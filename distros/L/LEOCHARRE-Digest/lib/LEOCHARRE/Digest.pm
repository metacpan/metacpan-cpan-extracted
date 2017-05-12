package LEOCHARRE::Digest;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);
use Exporter;
use Carp;
use String::ShellQuote;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(md5_cli);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub md5_cli {   
   my $abs = String::ShellQuote::shell_quote($_[0]);
   #my $r = `md5sum $abs 2>&1`; # to hide stderr
   my $r = `md5sum $abs`;
   $? and return; #and warn("Error getting md5sum on '$abs': err '$?'\n") and return;
   # md5sum already tells what the error is, if file is missing tells stderr what it was (the arg)
   chomp $r;
   $r=~s/\s.*//;
   $r=~s/^\W//;
   $r=~/^([0-9A-F]{32})/i or warn("Cant match 32 char sum into '$abs', result was '$r'") and return;
   return $1;
}

# # recreation of Digest::MD5::File
# sub _md5_Digest_MD5 {
#    my $abs = shift;
#    # slurp into mem? 
#    # this will eat the memory in the system
#    #
#    my $data = undef;
#    local $/;
#    open(FILE,'<',$abs);
#    $data = <FILE>;
#    require Digest::MD5;
#    my $md5 = Digest::MD5::md5_hex($data);
#    $data=undef;
#    return $md5;
# }
# 
# sub _md5_Digest_MD5_File {
#    my $abs = shift;   
#    require Digest::MD5::File;
#    my $md5 = Digest::MD5::File::file_md5_hex($abs);
#    return $md5;
# }
# 
# # only read part of file -sketchy
# sub _md5_lazy {
#    my $abs = shift;
# 
#    # set a length to read each time, a buffer
#    # let's set it at.. hmm... 25k
#    my $length = ( 1024 * 25 );
#    my $chunk;
#    open( FILE, '<', $abs) or die("cant open for reading $abs, $!");
#    read(FILE, $chunk, $length );
#    close FILE;   
#    return md5_hex($chunk);
# }





1;

__END__

=pod

=head1 NAME

LEOCHARRE::Digest - quick md5 sum output

=head1 SYNOPSIS

   use LEOCHARRE::Digest ':all';
   my $abs = '/home/myself/data.txt';
   my $sum = md5_cli($abs);

=head1 DESCRIPTION

This is a wrapper around gnu coreutils md5sum.
Is much quicker than some Digest::MD5::File and such.

=head1 SUBS

=head2 md5_cli()

Arg is path to file on disk.
Calls md5sum. Returns undef on failure. If not on disk, md5sum warns.
Filename can contain funny chars, we use String::ShellQuote to sanitize.

=head1 CAVEATS

Will only work on posix, with gnu coreutils.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


