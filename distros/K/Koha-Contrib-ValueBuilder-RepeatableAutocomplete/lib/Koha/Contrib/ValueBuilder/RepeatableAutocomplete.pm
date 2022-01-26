package Koha::Contrib::ValueBuilder::RepeatableAutocomplete;
use strict;
use warnings;
use JSON qw(to_json);

# ABSTRACT: Repeatable autcomplete value-builder for Koha

our $VERSION = '1.002'; # VERSION

sub build_builder_inline {
    my $class = shift;
    my $args  = shift;

    my $builder = sub {
        my ($params) = @_;

        my $val = {
            function_name => $params->{id},
            data          => to_json( $args->{data} ),
            target        => $args->{target},
            minlength     => $args->{minlength} || 3,
        };

        my $res = <<'EOJS';
<script>
function Focus[% function_name %](event) {
    var dropdown = [% data %];

    var inputField = $(event.target);
    var currentVal = inputField.val();
    var field      = inputField.attr('id').replace(/_subfield_.*$/,'');
    var target     = $(inputField.closest('ul').find('input[id^="' + field + '_subfield_[% target %]"]')[0]);

    inputField.autocomplete({
        source: dropdown,
        minLength: [% minlength %],
        select: function( event, ui ) {
            event.preventDefault();
            inputField.val( ui.item.label );
            target.val( ui.item.value );
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
        $res =~ s/\[%\s?(.*?)\s?%\]/$val->{$1} || ''/eg;
        return $res;
    };
    return { builder => $builder, };
}

q{ listening to: Fatima Spar & JOV: The Voice Within };

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete - Repeatable autcomplete value-builder for Koha

=head1 VERSION

version 1.002

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
            minlength => 3.
            data      => [ { label=>"Foo", value=>'foo', ... } ],
        }
    );

Parameters:

=over

=item * C<target>: required

The subfield of the MARC field into which the selected C<value> is stored.

=item * C<data>: required

An ARRAY of HASHes, each hash has to contain a key C<label> (which
will be what the users enter) and a key C<value> which has to contain
the value to be stored in C<target>

=item * C<minlength>; optional, defaults to 3

Input length that will trigger the autocomplete.

=back

=head2 Usage in Koha

You will need to write a C<value_builder> Perl script and put it into
F</usr/share/koha/intranet/cgi-bin/cataloguing/value_builder>. You can
find some example value-builder scripts in L<example/>. The should
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
