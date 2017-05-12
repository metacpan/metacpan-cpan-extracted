package HTML::DTD;

use strict;
use warnings;
no warnings "uninitialized";
use Scalar::Util qw( blessed );
use Carp qw( carp confess croak );
use File::ShareDir ();
use Path::Class;

our $VERSION = "0.04";

sub new : method {
    my $caller = shift;
    croak "No arguments allowed to new()" if @_;
    my $holder = "";
    return bless \$holder, $caller;
}

sub dtds : method {
    my $caller = shift;
    croak "No arguments allowed to dtds()" if @_;
    my $dir = Path::Class::Dir->new( File::ShareDir::dist_dir("HTML-DTD") );
    opendir my $dh, $dir or die "Could not open '$dir' for reading: $!";
    return sort grep /\.dtd\z/, readdir $dh;
}

sub get_dtd_fh {
    my $arg = shift;
    my $dtd = shift if $arg eq __PACKAGE__ or blessed($arg) eq __PACKAGE__;
    $dtd ||= $arg;
    croak "DTD name required" unless $dtd;
    my $file = File::ShareDir::dist_file("HTML-DTD", $dtd);
    open my $fh, "<", $file or croak "Could not open '$file' for reading: $!";
    return $fh;
}

sub get_dtd_path {
    my $arg = shift;
    my $dtd = shift if $arg eq __PACKAGE__ or blessed($arg) eq __PACKAGE__;
    $dtd ||= $arg;
    croak "DTD name required" unless $dtd;
    return Path::Class::File->new( File::ShareDir::dist_file("HTML-DTD", $dtd) );
}

sub get_dtd {
    my $arg = shift;
    my $dtd = shift if $arg eq __PACKAGE__ or blessed($arg) eq __PACKAGE__;
    $dtd ||= $arg;
    croak "DTD name required" unless $dtd;
    my $file = File::ShareDir::dist_file("HTML-DTD", $dtd);
    open my $fh, "<", $file or croak "Could not open '$file' for reading: $!";
    local $/ = undef;
    my $raw = <$fh>;
    close $fh;
    return $raw;
}

1;

__END__

=pod

=head1 NAME

HTML::DTD - local access to the standard and historical HTML DTDs.

=head1 VERSION

0.04

=head1 SYNOPSIS

 use strict;
 use warnings;
 use HTML::DTD;
 
 print join("\n", HTML::DTD->dtds), "\n";
 
 my $html_dtd = HTML::DTD->new();
 my $dtd   = $html_dtd->get_dtd("xhtml1-transitional.dtd");
 my $same  = HTML::DTD->get_dtd("xhtml1-transitional.dtd");
 my $ditto = HTML::DTD::get_dtd("xhtml1-transitional.dtd");

=head1 DESCRIPTION

Installs HTML DTD files locally for easy, reliable access.

=head1 METHODS

=over 4

=item B<new>

Create an L<HTML::DTD> object. Not particularly necessary. Mostly a placeholder if the code ever grows. All object methods can be called as class methods and functions.

=item B<get_dtd>

Takes a DTD name, see the list below, return a string of the DTD.

=item B<get_dtd_fh>

Returns a filehandle to the DTD.

=item B<get_dtd_path>

Returns a L<Path::Class> object for the DTD.

=item B<dtds>

Returns a list of the available DTD names. Currently available-

    html-0.dtd
    html-1.dtd
    html-1s.dtd
    html-2-strict.dtd
    html-2.dtd
    html-3-2.dtd
    html-3-strict.dtd
    html-3.dtd
    html-4-0-1-frameset.dtd
    html-4-0-1-loose.dtd
    html-4-0-1-strict.dtd
    html-4-frameset.dtd
    html-4-loose.dtd
    html-4.strict.dtd
    html-cougar.dtd
    html.dtd
    xhtml1-frameset.dtd
    xhtml1-strict.dtd
    xhtml1-transitional.dtd
    xhtml11.dtd

=back

=head1 TODO

Should probably have an author test which compares the DTDs to their URIs.

Speaking of which... there should probably be the necessary header strings available for each DTD as a courtesy.

=head1 BUGS AND LIMITATIONS

This is half a stub module to bring in something I find useful: locally installed and easily found DTDs. I can imagine other ways it could be useful but don't yet have clear need myself. If you do, let me know. I love good feedback and bug reports. Please report any bugs or feature requests directly to me via email or through the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=HTML::DTD>.

=head1 SEE ALSO

L<Path::Class>.

=head1 COPYRIGHT & LICENSE

Copyright (E<copy>) 2008-2010 Ashley Pond V.

This program is free software; you can redistribute it or modify it or
both under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except
when otherwise stated in writing the copyright holders or other
parties provide the software "as is" without warranty of any kind,
either expressed or implied, including, but not limited to, the
implied warranties of merchantability and fitness for a particular
purpose. The entire risk as to the quality and performance of the
software is with you. Should the software prove defective, you assume
the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be liable
to you for damages, including any general, special, incidental, or
consequential damages arising out of the use or inability to use the
software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of such
damages.

=cut
