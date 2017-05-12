package ExtUtils::FindFunctions;
use strict;
use Carp;
use DynaLoader;
require Exporter;

{   no strict;
    $VERSION = '0.02';
    @ISA     = qw(Exporter);
    @EXPORT  = qw(&have_functions);
}

=head1 NAME

ExtUtils::FindFunctions - Find functions in external libraries

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use ExtUtils::FindFunctions;

    my @check = qw(pcap_findalldevs  pcap_open_dead  pcap_setnonblock  pcap_lib_version);
    my @funcs = have_functions(libs => '-lpcap', funcs => \@check, return_as => 'array');

=head1 DESCRIPTION

This module provides the C<have_functions()> function which can be used to 
check if given functions are provided by an external library. Its aim is 
to be used as an embedded library by F<Makefile.PL> which needs such 
facilities. Use the B<install-extutils-findfunctions> command to embed it 
in your distribution.

=head1 EXPORT

The module exports by default the C<have_functions()> function.

=head1 FUNCTIONS

=head2 have_functions()

Load the specified libraries and search for the given functions names. 
The results are returned as an array or as an hash depending on the 
C<return_as> parameter.

B<Parameters>

=over

=item *

C<libs> - specify the libraries to load; this argument will be given 
to C<DynaLoader::dl_findfile()>

=item *

C<funcs> - a reference to the list of functions to search

=item *

C<return_as> - specify the type of the result, either as an C<array> 
or as a C<hash>. As an array, only the functions found in the libraries 
are returned. As a hash, the keys are the function names and their value
indicates if the function is present or not.

=back

=cut

sub have_functions {
    my %args = @_;
    my %funcs = ();

    # check params
    defined $args{$_} or croak "error: Missing parameter '$_'.\n" for qw(libs funcs return_as);

    $args{return_as} ||= 'array';
    $args{return_as} =~ /^(?:array|hash)$/
        or croak "error: Incorrect value for parameter 'return_as'.\n";

    my @libs = ref $args{libs} eq ''      ? $args{libs}
             : ref $args{libs} eq 'ARRAY' ? @{$args{libs}}
             : croak "error: Incorrect argument for parameter 'libs'.\n";

    # search for functions
    for my $lib (@libs) {
        my @paths = DynaLoader::dl_findfile($lib);

        for my $path (@paths) {
            my $libref = DynaLoader::dl_load_file($path);

            for my $func (@{$args{funcs}}) {
                my $symref = DynaLoader::dl_find_symbol($libref, $func);
                $funcs{$func} = ! ! defined $symref;
            }

            DynaLoader::dl_unload_file($libref);
        }
    }

    return $args{return_as} eq 'hash' ? %funcs
           : grep { $funcs{$_} } sort keys %funcs;
}


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-extutils-findfunctions at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-FindFunctions>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::FindFunctions

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-FindFunctions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-FindFunctions>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-FindFunctions>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-FindFunctions>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2006 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of ExtUtils::FindFunctions
