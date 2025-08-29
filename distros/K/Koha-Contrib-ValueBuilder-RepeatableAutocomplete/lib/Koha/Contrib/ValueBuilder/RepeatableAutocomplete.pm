package Koha::Contrib::ValueBuilder::RepeatableAutocomplete;
use strict;
use warnings;
use JSON qw(to_json);

# ABSTRACT: Repeatable autcomplete value-builder for Koha

our $VERSION = '1.006'; # VERSION

sub build_builder_inline {
    my $class = shift;
    my $args  = shift;

    my $builder = sub {
        my ($params) = @_;

        my $val = {
            function_name => $params->{id},
            data          => to_json( $args->{data} ),
            target        => $args->{target},
            minlength     => $args->{minlength} // 3,
        };

        my $res = <<'EOJS';
<script>
function Focus[% function_name %](event) {
    var dropdown = [% data %];

    var inputField = $(event.target);
    var currentVal = inputField.val();
    var field      = inputField.attr('id').replace(/_subfield_.*$/,'');

    inputField.autocomplete({
        source: dropdown,
        minLength: [% minlength %],
        select: function( event, ui ) {
            event.preventDefault();

            const source_id_prefix = inputField.attr('id').match(/tag_\d+_subfield_[^_]+/);
            const sources = inputField.closest('ul').find(`input[id^=${source_id_prefix}]`);
            const sourceIdx = sources.index(inputField);

            const targets = inputField.closest('ul').find('input[id^="' + field + '_subfield_4"]');
            let target = targets[sourceIdx];

            if (target == undefined) {
                // must be a new source, create a new target
                targets.last().parent().parent().find('a.buttonPlus').click();
                target = inputField.closest('ul').find('input[id^="' + field + '_subfield_4"]').last();
            }
            inputField.val( ui.item.value_for_input || ui.item.label );
            $(target).val( ui.item.value_for_target );
            inputField.autocomplete('destroy');
            inputField.blur();
        },
        change: function (event, ui) {
            if(currentVal != inputField.val() && !ui.item){
                target.val('');
                inputField.val('');
            }
            inputField.autocomplete('destroy');
            inputField.blur();
        },
    });

    return 1;
}
</script>
EOJS
        $res =~ s{\[%\s?(.*?)\s?%\]}{$val->{$1} // ''}eg;
        return $res;
    };
    return { builder => $builder };
}

sub build_builder_inline_multiple {
    my $class = shift;
    my $args  = shift;

    my $builder = sub {
        my ($params) = @_;

        my $val = {
            function_name => $params->{id},
            data          => to_json( $args->{data} ),
            target_map    => to_json( $args->{target_map}),
            minlength     => $args->{minlength} // 3,
        };

        my $res = <<'EOJS';
<script>
function Focus[% function_name %](event) {
    var dropdown  = [% data %];
    var targetMap = [% target_map %];

    var inputField = $(event.target);
    var currentVal = inputField.val();
    var field      = inputField.attr('id').replace(/_subfield_.*$/,'');

    inputField.autocomplete({
        source: dropdown,
        minLength: [% minlength %],
        select: function( event, ui ) {
            event.preventDefault();
            inputField.val( ui.item.label );

            targetMap.forEach( function(element) {
                var target = $(inputField.closest('ul').find('input[id^="' + field + '_subfield_' + element.subfield + '"]')[0]);

                switch (element.type) {
                    case 'selected':
                        target.val( ui.item[element.key] );
                        break;
                    case 'literal':
                        target.val(element.literal);
                        break;
                }
            });

            inputField.autocomplete('destroy');
            inputField.blur();
        },
        change: function (event, ui) {
            if(currentVal != inputField.val() && !ui.item){
                inputField.val('');
                targetMap.forEach( function(element) {
                    var target = $(inputField.closest('ul').find('input[id^="' + field + '_subfield_' + element.subfield + '"]')[0]);
                    target.val('');
                });
            }
            inputField.autocomplete('destroy');
            inputField.blur();
        },
    });

    return 1;
}
</script>
EOJS
        $res =~ s{\[%\s?(.*?)\s?%\]}{$val->{$1} // ''}eg;
        return $res;
    };
    return { builder => $builder };
}



q{ listening to: Fatima Spar & JOV: The Voice Within };

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete - Repeatable autcomplete value-builder for Koha

=head1 VERSION

version 1.006

=head1 SYNOPSIS

  Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
          {   target => '4',
              data   => [
                { label => 'ArchitektIn', value => 'arc' },
                # and more...
              ] ,
          }
      );
  }

=head1 DESCRIPTION

C<Koha::Contrib::ValueBuilder::RepeatableAutocomplete> helps building
C<Koha Valuebuilder Plugins>. L<Koha|https://koha-community.org/> is
the world's first free and open source library system.

This module implements some functions that will generate the
JavaScript / jQuery needed by the Koha Edit Form to enable a simple
autocomplete lookup, while also working with repeatable MARC21 fields.

Please take a look at the helper modules included in this
distribution, which pack all the lookup values and their configuration
into easy to use functions:

=over

=item * L<Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA>

Values for Field C<100> and C<700> subfields C<$e> and C<$e>, creator
and other agents.

=back

=head2 Functions

=head3 build_builder_inline

Build JS to handle a short inline autocomplete lookup (data is
provided to the function, not loaded via AJAX etc). The field will be
inferred from the form element the value_builder is bound to.

  build_builder_inline(
        {   target    => '4',
            data      => [ { label=>"Foo", value=>'foo' }, ... ],
            minlength => 3.
        }
    );

Parameters:

=over

=item * C<target>: required

The subfield of the MARC field into which the selected C<value> is stored.

=item * C<data>: required

An ARRAY of HASHes, each hash has to contain a key C<label> (which
will be what the users enter) and a key C<value> which has to contain
the value to be stored in C<target>. An optional key
C<value_for_input> can be used if you need to set the input field to a
different value than what is returned in C<label>.

=item * C<minlength>; optional, defaults to 3

Input length that will trigger the autocomplete.

=back

=head3 build_builder_inline_multiple

Build JS to handle a short inline autocomplete lookup (data is
provided to the function, not loaded via AJAX etc). The selected value
will be inserted into multiple subfields. The field will be inferred
from the form element the value_builder is bound to.

  build_builder_inline(
        {   target_map => [
                { subfield=>'b', type=>'selected', key=>'value' },
                { subfield=>'a', type=>'selected', key=>'other' },
                { subfield=>'2', type=>'literal',  literal=>'rdacontent' }
            ],
            data      => [ { label=>"Foo", value=>'foo', other=>'FOO', }, ... ],
            minlength => 3.
        }
    );

Parameters:

=over

=item * C<target_map>: required

A list of subfields and how to fill them with data based on the selected value.

=over

=item * subfield: the subfield to fill

=item * type: how to fill the subfield. Currently we have two types:
C<selected> and C<literal>

=item * selected: If type is C<selected>, fill the subfield with the
value of the selected data mapped to the key specified here

-item * literal: If type is C<literal>, fill the subfield with this literal value

=back

=item * C<data>: required

An ARRAY of HASHes, each hash has to contain a key C<label> (which
will be what the users enter) and some more keys which can be mapped
to subfields using C<target_map> entries of type C<selected>.

Given this C<target_map>

  [
     { subfield=>'b', type=>'selected', key=>'value' },
     { subfield=>'a', type=>'selected', key=>'other' },
     { subfield=>'2', type=>'literal',  literal=>'rdacontent' }
  ],

And this C<data>

 { label=>"Foo", value=>'foo', other=>'FOO' }

Selecting "Foo" will store C<value> ("foo">) into subfield C<b>,
C<other> ("FOO">) into subfield C<a> and the literal value
"rdacontent" into C<2>.

=item * C<minlength>; optional, defaults to 3

Input length that will trigger the autocomplete.

=back

=head2 Usage in Koha

You will need to write a C<value_builder> Perl script and put it into
F</usr/share/koha/intranet/cgi-bin/cataloguing/value_builder>. You can
find some example value-builder scripts in F<example/>. The should
look something like this:

  #!/usr/bin/perl
  use strict;
  use warnings;
  
  use Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA qw(creator);
  
  return creator('de');

You than will have to enable this value_builder as a Plugin in the
respective MARC21 Framework / field / subfield.

=head1 Thanks

for supporting Open Source and giving back to the community:

=over

=item * L<HKS3|https://koha-support.eu>

=item * L<Steirmärkische Landesbibliothek|https://www.landesbibliothek.steiermark.at/>

=item * L<Camera Austria|https://camera-austria.at/>

=back

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@plix.at>

=item *

Mark Hofstetter <cpan@trust-box.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
