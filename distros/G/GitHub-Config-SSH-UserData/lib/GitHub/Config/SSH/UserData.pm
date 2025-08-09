package GitHub::Config::SSH::UserData;

use 5.010;
use strict;
use warnings;
use autodie;

use Carp;
use File::Spec::Functions;

use Exporter 'import';

use constant DEFAULT_CFG_FILE => catfile($ENV{HOME}, qw(.ssh config));

our $VERSION = '0.03';


our @EXPORT_OK = qw(get_user_data_from_ssh_cfg);


sub get_user_data_from_ssh_cfg {
  croak("Wrong number of arguments") if !@_ || @_ > 2;
  my $user_name = shift;
  my $config_file = shift // DEFAULT_CFG_FILE;
  croak("First argument must be a scalar (a string)") if ref($user_name);
  croak("Second argument must be a scalar (a string)") if ref($config_file);

  open(my $hndl, '<', $config_file);
  my %seen;
  my $cfg_data;
  while (defined(my $line = <$hndl>)) {
    if ($line =~ /^Host\s+github-(\S+)\s*$/) {
      my $current_user_name = $1;
      croak("$current_user_name: duplicate user name") if exists($seen{$current_user_name});
      $seen{$current_user_name} = undef;
      next if $current_user_name ne $user_name;
      $line = <$hndl> // die("$config_file: unexpected EOF");
      $line =~ /^\s*\#\s*
                User:\s*
                (?:([^<>\s]+(?:\s+[^<>\s]+)*)\s*)?  # User name (optional)
                <(\S+?)>\s*                         # Email address for git configuration
                (?:<([^<>\s]+)>\s*)?                # Second email address (optional)
                (?:(\S+(\s+\S+)))?$                 # other data (optional)
               /x or
        croak("$current_user_name: missing or invalid user info");
      @{$cfg_data}{qw(full_name email email2 other_data)} = @{^CAPTURE};
      $cfg_data->{full_name} //= $current_user_name;
      delete @{$cfg_data}{ grep { not defined $cfg_data->{$_} } keys %{$cfg_data} };
      last;
    }
  }
  close($hndl);
  croak("$user_name: user name not in $config_file") unless $cfg_data;
  return $cfg_data;
}


1; # End of GitHub::Config::SSH::UserData

=pod

=head1 NAME

GitHub::Config::SSH::UserData - Read user data from comments in ssh config file

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

   use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);

   my $udata = get_user_data_from_ssh_cfg("johndoe");

or

   my $udata = get_user_data_from_ssh_cfg("johndoe", $my_ssh_config_file);

=head1 DESCRIPTION

This module exports a single function (C<get_user_data_from_ssh_cfg()>) that
is useful when using multiple GitHub accounts with SSH keys.  First, you
should read this gist L<https://gist.github.com/oanhnn/80a89405ab9023894df7>
and follow the instructions.

To use C<get_user_data_from_ssh_cfg()>, you must add information to your ssh config file (default
F<~/.ssh/config>) by adding comments like this:

  Host github-ALL-ITEMS
  #  User: John Doe <main@addr.xy> <foo@bar> additional data
     HostName github.com
     IdentityFile ~/.ssh/abc
     IdentitiesOnly yes

  Host github-minimal
  #  User: <main@addr.xy>
     HostName github.com
     IdentityFile ~/.ssh/mini
     IdentitiesOnly yes

  Host github-std
  #  User: Jonny Controlletti <main-jc@addr.xy>
     HostName github.com
     IdentityFile ~/.ssh/std
     IdentitiesOnly yes

  Host github-std-data
  #  User: Alexander Platz <AlexPl@addr.xy> more data
     HostName github.com
     IdentityFile ~/.ssh/aaaaa
     IdentitiesOnly yes

The function looks for C<Host> names beginning with C<github->. It assumes that
the part after the hyphen is your username on github. E.g., in the example
above the github usernames are C<ALL-ITEMS>, C<minimal>, C<std> and C<std-data>.

The next line must be a comment line beginning with C<User:> followed by an
optional name (full name, may contain spaces) followed by one or two email addresses in angle
brackets, optionally followed by another string. See the examples above.

The following function can be exported on demand:

=over

=item C<get_user_data_from_ssh_cfg(I<USER_NAME>, I<SSH_CFG_FILE>)>

=item C<get_user_data_from_ssh_cfg(I<USER_NAME>)>

The function scans file I<C<SSH_CFG_FILE>> (default is
C<$ENV{HOME}/.ssh/config> and looks for C<Host github-I<USER_NAME>>. Then is
scans the C<User:> comment in the next line (see description above). It
returns a reference to a hash containing:

=over

=item C<full_name>

The full name before the first email address. If no full name is specified,
then the value is set to I<C<USER_NAME>>.

This key always exists.

=item C<email>

The first email address. This key always exists.

=item C<email2>

The second email address. This key only exists if a second email address is specified.

=item C<other_data>

Trailing string. This key only exists if a second email address if there is
such a trailing string.

=back

If C<Host github-I<USER_NAME>> is not found, or if there is no corresponding C<User:> comment, or if this comment is not formatted correctly, a fatal error occurs.

=back


=head1 AUTHOR

Klaus Rindfrey, C<< <klausrin at cpan.org.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-github-config-ssh-userdata
at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GitHub-Config-SSH-UserData>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SEE ALSO

L<https://gist.github.com/oanhnn/80a89405ab9023894df7>

L<App::ghmulti>, L<Git::RemoteURL::Parse>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GitHub::Config::SSH::UserData


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=GitHub-Config-SSH-UserData>

=item * Search CPAN

L<https://metacpan.org/release/GitHub-Config-SSH-UserData>

=item * GitHub Repository

L<https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata>


=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

