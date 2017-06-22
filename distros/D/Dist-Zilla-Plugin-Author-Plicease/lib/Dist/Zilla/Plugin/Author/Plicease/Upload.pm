package Dist::Zilla::Plugin::Author::Plicease::Upload;

use 5.008001;
use Moose;

# ABSTRACT: Upload a dist to CPAN
our $VERSION = '2.15'; # VERSION


extends 'Dist::Zilla::Plugin::UploadToCPAN';

has cpan => (
  is      => 'ro',
  default => sub { 1 },
);

has scp_dest => (
  is      => 'ro',
  default => sub { 'ollisg@ratbat.wdlabs.com:web/sites/dist' },
);

has url => (
  is      => 'ro',
  default => sub { 'http://dist.wdlabs.com/' },
);

around before_release => sub {
  my $orig = shift;
  my $self = shift;
  
  # don't check username / password here
  # do it during release
};

around release => sub {
  my $orig = shift;
  my $self = shift;
  
  if($self->cpan && $self->zilla->chrome->prompt_yn("upload to CPAN?"))
  {
    eval {
      die "no username" unless length $self->username;
      die "no password" unless length $self->password;
      $self->$orig(@_);
    };
    if(my $error = $@)
    {
      $self->zilla->log("error uploading to cpan: $error");
      $self->zilla->log("you will have to manually upload the dist");
    }
  }
  else
  {
    my($archive) = @_;
    use autodie qw( :system );
    my @cmd = ('scp', '-q', $archive, $self->scp_dest);
    $self->zilla->log("% @cmd");
    eval { system @cmd };
    if(my $error = $@)
    {
      $self->zilla->log("NOTE SCP FAILED: $error");
      $self->zilla->log("manual upload will be required");
    }
    else
    {
      $self->zilla->log("download URL: " . $self->url . "$archive");
    }
  }
  
  return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Upload - Upload a dist to CPAN

=head1 VERSION

version 2.15

=head1 SYNOPSIS

=head1 DESCRIPTION

This works similar to L<Dist::Zilla::Plugin::UploadToCPAN>.  Except:

=over 4

=item Non fatal

It doesn't die if the upload does not succeed.  In my work flow I usually
just upload the tarball manually when the upload fails.  Sometimes I also
want to do the release step when I am not connected to the Internet.

=item Asks first

It asks if you really want to upload to CPAN.  Some of my releases go to
my server using C<scp> so if you either say no, or set C<cpan> to C<0>
in the configuration it will do this instead.

=back

Basically just some personal preferences, you can and probably should
replace this with C<[UploadToCPAN]> if you are taking over a dist.

=head1 OPTIONS

=head2 cpan

Either C<1> or C<0>.  Set to C<0> and dist will not be uploaded to CPAN
on release.

=head2 scp_dest

Valid C<scp> destination if CPAN upload is disabled.

=head2 url

Base web URL if CPAN upload is disabled.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
