use strict;
use 5.010;

package FusqlFS::Formatter;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Formatter - formatter backend for FusqlFS

=head1 SYNOPSIS

    my ($dump, $load) = FusqlFS::Formatter->init('yaml');
    print $dump->($data);
    my $data = $load->($data);

=head1 DESCRIPTION

This class is a frontend to different data formatters for FusqlFS.

=head1 METHODS

=over

=cut

use Carp;

our %FORMATTERS = (
    xml => [
        'XML/Simple.pm',
        sub { XMLout($_[0], NoAttr => 1) },
        sub { XMLin($_[0], NoAttr => 1) },
        ],
    yaml => [
        'YAML/Tiny.pm',
        \&YAML::Tiny::Dump,
        \&YAML::Tiny::Load,
        ],
    json => [
        'JSON/Syck.pm',
        \&JSON::Syck::Dump,
        \&JSON::Syck::Load,
        ],
);

=item init

Initialize dumper and loader for given output format.

Input: $format
Output: &dumper, &loader

=begin testing init

#!noinst
my ($dump, $load) = FusqlFS::Formatter->init('native');
is ref $dump, 'CODE', 'Dumper defined';
is ref $load, 'CODE', 'Loader defined';

=end testing
=cut
sub init
{
    my $class = shift;
    my $format = shift||'yaml';

    my $package;
    my $formatter;

    $formatter = $FORMATTERS{$format} || [
        package_file($package = 'FusqlFS::Formatter::'.ucfirst(lc($format))),
        eval qq{\\&${package}::Dump},
        eval qq{\\&${package}::Load},
    ];

    if ($formatter->[0]) {
        eval { require $formatter->[0]; };
        if ($@) {
            croak "Failed to load native formatter" if ($format eq 'native');

            if ($format eq 'yaml') {
                carp "Failed to load formatter `yaml', falling back to `native'";
                return $class->init('native');
            } else {
                carp "Failed to load formatter `$format', falling back to `yaml'";
                return $class->init('yaml');
            }
        }
    }

    return $formatter->[1], $formatter->[2];
}

sub package_file {
    my $package = shift;
    $package =~ s{::}{/}g;
    $package .= '.pm';
    return $package;
}

1;

__END__

=back
