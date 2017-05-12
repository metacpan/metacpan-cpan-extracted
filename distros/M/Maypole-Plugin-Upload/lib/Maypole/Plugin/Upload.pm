package Maypole::Plugin::Upload;

our $VERSION='0.02';

use constant APACHE2 => $mod_perl::VERSION && $mod_perl::VERSION >= 1.99;

if (APACHE2) {
    require Apache2;
    require Apache::Upload;
}

sub upload {
   my ($r,$field) = @_;
   my ($filename,$fh,$content,$mime);
   if ($r->{ar}) {
       my $au=$r->{ar}->upload($field);
       $filename=$au->filename;
       $fh=$au->fh;
       $mime=(APACHE2 ? $au->info->{"Content-type"} : $au->info("Content-type"));
   } elsif ($r->{cgi}) {
       $filename=$r->{cgi}->param($field);
       $fh=$r->{cgi}->upload($field);
       $mime=(ref $r->{cgi} eq "CGI" ?
       $r->{cgi}->uploadInfo($filename,'mime') :
       $r->{cgi}->upload_info($filename,'mime') );
	
   } else {
       die("File uploads not supported");
   }
   $content=do { local $/; <$fh> };
   warn "Got Content-length:".length($content);
   return (wantarray ? ( filename=>$filename,
		         content =>$content,
		         mimetype=>$mime ) : $content);
}
1;

=head1 NAME

Maypole::Plugin::Upload - Handle file uploads in Maypole

=head1 SYNOPSIS

  my %upload = $r->upload('file');
  return unless $upload{mimetype} =~ m|^image/|;

=head1 DESCRIPTION

This plugin adds a upload method to your Maypole request object to allow
you to access file uploads in a platform neutral way.


=head1 METHODS

=over 4

=item upload

This method takes the form name as parameter, and returns either a hash 
with 'content', 'filename' and 'mimetype', or the content if used
in scalar context.

=back

=head1 AUTHOR

Marcus Ramberg C<marcus@thefeed.no>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
