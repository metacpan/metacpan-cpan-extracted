use strict;
use warnings;

package Footprintless::App::DocumentationUtil;
$Footprintless::App::DocumentationUtil::VERSION = '1.27';
# ABSTRACT: A utility class for generating help documentation from POD
# PODNAME: Footprintless::App::DocumentationUtil

use Exporter qw(import);
use File::Spec;
use Log::Any;

my $logger = Log::Any->get_logger();

our @EXPORT_OK = qw(
    abstract
    description
    examples
    pod_section
);

sub abstract {
    my ($self_or_class) = @_;

    my $pm_file = _pm_file($self_or_class);
    return '(unknown)' unless ($pm_file);

    require Footprintless::Util;
    return Footprintless::Util::slurp($pm_file) =~ /^#+\s*ABSTRACT: (.*)$/m ? $1 : '(unknown)';
}

sub description {
    return pod_section( $_[0], 'DESCRIPTION', 0, qr/Description:\n/ );
}

sub examples {
    return pod_section( $_[0], 'EXAMPLES' );
}

sub pod_section {
    my ( $self_or_class, $section, $indent, $remove ) = @_;

    my $pm_file = _pm_file($self_or_class)
        || return $self_or_class->abstract();

    my $pod = '';
    open( my $output, '>', \$pod );

    require Pod::Usage;
    Pod::Usage::pod2usage(
        -input    => $pm_file,
        -output   => $output,
        -exit     => "NOEXIT",
        -verbose  => 99,
        -sections => $section,
        indent    => $indent
    );

    if ($pod) {
        $pod =~ s/$remove//m if ($remove);
        chomp($pod);
    }

    return $pod;
}

sub _pm_file {
    my ($self_or_class) = @_;
    my $class = ref($self_or_class) || $self_or_class;

    my @pm_file_parts = split( /::/, $class );
    $pm_file_parts[$#pm_file_parts] .= '.pm';
    my $pm_file = File::Spec->catfile(@pm_file_parts);

    my $path = $INC{$pm_file};
    unless ($path) {
        foreach my $prefix (@INC) {
            my $prefix_path = File::Spec->catfile( $prefix, $pm_file );
            if ( -f $prefix_path ) {
                $path = $prefix_path;
                last;
            }
        }
    }

    return $path;
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::DocumentationUtil - A utility class for generating help documentation from POD

=head1 VERSION

version 1.27

=head1 EXPORT_OK

=head2 abstract($self_or_class)

Returns the content of the C<ABSTRACT> section of the pod for 
C<$self_or_class>.

=head2 description($self_or_class)

Returns the content of the C<DESCRIPTION> section of the pod for 
C<$self_or_class>.

=head2 examples($self_or_class)

Returns the content of the C<EXAMPLES> section of the pod for 
C<$self_or_class>.

=head2 pod_section($self_or_class, $section, $indent, $remove)

Returns the content of the C<$section> section of the pod for 
C<$self_or_class> with indent level C<$indent>.  If specified, 
C<$remove> a regex used to find content to remove.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=back

=cut
