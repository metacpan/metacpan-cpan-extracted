package App::Installer;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Application class for Installer
$App::Installer::VERSION = '0.904';
use Moo;
use Path::Class;
use IO::All;
use namespace::clean;

has target => (
  is => 'ro',
  required => 1,
);

has file => (
  is => 'ro',
  lazy => 1,
  default => sub { 'installer' },
);

has installer_code => (
  is => 'ro',
  predicate => 1,
);

has 'url' => (
  is => 'ro',
  predicate => 1,
);

sub install_to_target {
  my ( $self ) = @_;
  my $target = $self->target;
  $target = dir($target)->absolute->stringify;
  my $installer_code;
  if ($self->has_installer_code) {
    $installer_code = $self->installer_code;
  } elsif ($self->has_url) {
    $installer_code = io($self->url)->get->content;
  } else {
    $installer_code = io($self->file)->all;
  }
  my $target_class = 'App::Installer::Sandbox'.$$;

  my ( $err );
  {
    local $@;
    eval <<EVAL;
package $target_class;
no strict;
no warnings;
use Installer;
use IO::All -utf8;

install_to '$target' => sub {
  $installer_code;
};

EVAL
    $err = $@;
  }

  if ($err) { die "$err" };

}

1;

__END__

=pod

=head1 NAME

App::Installer - Application class for Installer

=head1 VERSION

version 0.904

=head1 DESCRIPTION

You should use this through the command L<installto>.

B<TOTALLY BETA, PLEASE TEST :D>

=head1 SUPPORT

IRC

  Join #cindustries on irc.quakenet.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-installer
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-installer/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
