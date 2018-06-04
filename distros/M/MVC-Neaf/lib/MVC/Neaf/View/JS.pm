package MVC::Neaf::View::JS;

use strict;
use warnings;

our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::View::JS - JSON-based view for Not Even A Framework.

=head1 SYNOPSIS

See L<MVC::Neaf>.

    use MVC::Neaf;

    # define route ...
    sub {
        return {
            # your data ...
            -view => 'JS',                 # this is the default as of 0.20
            -jsonp => 'my.jsonp.callback', # this is optional
        }
    };

Will result in your application returning raw data in JSON/JSONP format
instead or rendering a template.

=head1 METHODS

=cut

use Carp;
use MVC::Neaf::Util qw(JSON);

use parent qw(MVC::Neaf::View);

my $js_id_re = qr/[A-Z_a-z][A-Z_a-z\d]*/;
my $jsonp_re = qr/^$js_id_re(?:\.$js_id_re)*$/;

=head2 new( %options )

%options may include:

=over

=item * want_pretty - sort keys & indent output

=item * want_sorted - sort keys (this defaults to want_pretty)

=item * preserve_dash - don't strip dashed options. Useful for debugging.

=back

=cut

my %new_keys;
$new_keys{$_}++ for qw(want_pretty want_sorted preserve_dash);
sub new {
    my ($class, %opt) = @_;

    my @extra = grep { !$new_keys{$_} } keys %opt;
    croak "NEAF $class->new: unexpected keys @extra"
        if @extra;

    $opt{want_sorted} = $opt{want_pretty}
        unless defined $opt{want_sorted};
    # No utf8 here (yet), will encode upon leaving the perimeter
    my $codec = JSON->new->allow_blessed->convert_blessed
        ->allow_unknown->allow_nonref;
    $codec->pretty(1)
        if $opt{want_pretty};
    $codec->canonical(1)
        if $opt{want_sorted};

    return bless {
        %opt,
        codec => $codec,
    }, $class;
};

=head2 render( \%data )

Returns a scalar with JSON-encoded data.

=cut

sub render {
    my ($self, $data) = @_;

    my $callback = $data->{-jsonp};
    my $type = $data->{-type};

    if( exists $data->{-payload} || exists $data->{-serial} ) {
        $data = $data->{-payload} || $data->{-serial};
    }
    elsif ( !$self->{preserve_dash} ) {
        # This is the default - get rid of control keys, but
        #     don't spoil original data
        $data = do {
            my %shallow_copy;
            /^-/ or $shallow_copy{$_} = $data->{$_}
                for keys %$data;
            \%shallow_copy;
        };
    }

    my $content = $self->{codec}->encode( $data );
    return $callback && $callback =~ $jsonp_re
        ? ("$callback($content);", "application/javascript; charset=utf-8")
        : ($content, "application/json; charset=utf-8");
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
