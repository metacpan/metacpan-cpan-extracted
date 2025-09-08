package Dist::PolicyFiles;

use 5.014;
use strict;
use warnings;

use feature ':5.10';

our $VERSION = '0.02';


use Carp;
use File::Basename;
use File::Spec::Functions;

use Software::Security::Policy::Individual;
use Text::Template;
use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);



sub new {
  my $class = shift;
  my %args = (dir => '.', prefix => q{}, @_);
  state $allowed = {map {$_ => undef} qw(dir
                                         email
                                         full_name
                                         login
                                         module
                                         prefix
                                         uncapitalize)};
  $args{uncapitalize} = !!$args{uncapitalize};
  foreach my $arg (keys(%args)) {
    croak("$arg: unsupported argument") if !exists($allowed->{$arg});
    croak("$arg: value is not a scalar") if ref($args{$arg});
  }
  delete @args{ grep { !defined $args{$_} } keys %args };
  do {croak("$_: missing mandatory argument") if !exists($args{$_})} for (qw(login module));
  my $self = bless(\%args, $class);
  if (!(exists($self->{email}) && exists($self->{full_name}))) {
    my $udata = get_user_data_from_ssh_cfg($self->{login});
    $self->{email} //= $udata->{email2} // $udata->{email}
      // die("Could not determine email address");      # Should never happen.
    $self->{full_name} //= $udata->{full_name}
      // die("Could not determine user's full name");   # Should never happen.
  }
  return $self;
}


sub dir          {$_[0]->{dir}}
sub email        {$_[0]->{email}}
sub full_name    {$_[0]->{full_name}}
sub login        {$_[0]->{login}}
sub module       {$_[0]->{module}}
sub prefix       {$_[0]->{prefix}}
sub uncapitalize {$_[0]->{uncapitalize}}


sub create_contrib_md {
  my $self = shift;
  my $contrib_md_tmpl = shift;
  croak('Unexpected argument(s)') if @_;
  croak('Missing --module: no module specified') unless exists($self->{module});
  my $contrib_md_tmpl_str = defined($contrib_md_tmpl) ?
    do { local ( *ARGV, $/ ); @ARGV = ($contrib_md_tmpl); <> }
    :
    <<'EOT';
# Contributing to This Perl Module

Thank you for your interest in contributing!

## Reporting Issues

Please open a
[CPAN request]({$cpan_rt})
or a
[GitHub Issue]({$github_i})
if you encounter a bug or have a suggestion.
Include the following if possible:

- A clear description of the issue
- A minimal code example that reproduces it
- Expected and actual behavior
- Perl version and operating system

## Submitting Code

Pull requests are welcome! To contribute code:

1. Fork the repository and create a descriptive branch name.
2. Write tests for any new feature or bug fix.
3. Ensure all tests pass using `prove -l t/` or `make test`.
4. Follow the existing code style, especially:
   - No tabs please
   - No trailing whitespace please
   - 2 spaces indentation
5. In your pull request, briefly explain your changes and their motivation.


## Creating a Distribution (Release)

This module uses MakeMaker for creating releases (`make dist`).


## Licensing

By submitting code, you agree that your contributions may be distributed under the same license as the project.

Thank you for helping improve this module!

EOT
#Don't append a semicolon to the line above!

  (my $mod_name = (split(/,/, $self->{module}))[0]) =~ s/::/-/g;
  my $cpan_rt  = "https://rt.cpan.org/NoAuth/ReportBug.html?Queue=$mod_name";
  my $repo = $self->{prefix} . ($self->{uncapitalize} ? lc($mod_name) : $mod_name);
  my $github_i = "https://github.com/$self->{login}/$repo/issues";
  my $tmpl_obj = Text::Template->new(SOURCE => $contrib_md_tmpl_str, TYPE => 'STRING')
    or croak("Couldn't construct template: $Text::Template::ERROR");

  my $tmpl_vars = {cpan_rt  => $cpan_rt, github_i => $github_i};
  @{$tmpl_vars}{qw(email full_name module)} = @{$self}{qw(email full_name module)};
  my $contrib = $tmpl_obj->fill_in(HASH => $tmpl_vars)
    // croak("Couldn't fill in template: $Text::Template::ERROR");
    open(my $fh, '>', catfile($self->{dir}, 'CONTRIBUTING.md'));
    print $fh ($contrib, "\n");
    close($fh);
}



sub create_security_md {
  my $self = shift;
  my %args = (maintainer => sprintf("%s <%s>", @{$self}{qw(full_name email)}),
              program    => $self->{module},
              @_);
  if (!exists($args{url})) {
    (my $m = $self->{module}) =~ s/::/-/g;
    $m = lc($m) if $self->{uncapitalize};
    $args{url} = "https://github.com/$self->{login}/$self->{prefix}${m}/blob/main/SECURITY.md";
  }
  delete @args{ grep { !defined $args{$_} || $args{$_} eq q{}} keys %args };
  open(my $fh, '>', catfile($self->{dir}, 'SECURITY.md'));
  print $fh (Software::Security::Policy::Individual->new(\%args)->fulltext);
  close($fh);
}


1; # End of Dist::PolicyFiles


__END__

=pod

=head1 NAME

Dist::PolicyFiles - Generate CONTRIBUTING.md and SECURITY.md

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Dist::PolicyFiles;

    my $obj = Dist::PolicyFiles->new(login => $login_name, module => $module);
    $obj->create_contrib_md();
    $obj->create_security_md();

=head1 DESCRIPTION

This module is used to generate the policy files F<CONTRIBUTING.md> and
F<SECURITY.md>. It comes with the L<dist-policyfiles> command line tool.

=head2 METHODS

=head3 Constructor

The constructor C<new()> accepts the following named arguments, where C<login>
and C<module> are mandatory:

=over

=item C<dir>

Optional. Directory where the policy files should be written. By default, this
is the current working directory. See also accessor of the same name.

=item C<email>

Optional. User's email address. If not specified, C<new()> tries to read it
from comments in F<HOME/.ssh/config> (see L<GitHub::Config::SSH::UserData>).

See also the accessor method of the same name.

=item C<full_name>

Optional. User's full name. If not specified, C<new()> tries to read it from
comments in F<HOME/.ssh/config> (see L<GitHub::Config::SSH::UserData>).

See also the accessor method of the same name.

=item C<login>

Mandatory. User's github login name.

See also the accessor method of the same name.

=item C<module>

Mandatory. Module name.

See also the accessor method of the same name.

=item C<prefix>

Optional. Prefix for repo name, see method C<create_security_md()>. Default is
an empty string.

See also the accessor method of the same name.

=item C<uncapitalize>

Optional. Set this to I<C<true>> if your repo name is lower case, see method
C<create_security_md()>. Default is I<C<false>>.

See also the accessor method of the same name.

=back


=head3 Generation of policy files

=over

=item C<create_contrib_md(I<CONTRIB_MD_TMPL>)>

=item C<create_contrib_md()>

Creates F<CONTRIBUTING.md> in directory C<dir> (see corresponding constructor
argument). Optional argument I<C<CONTRIB_MD_TMPL>> is the name of a template
file (see L<Text::Template>) for this policy. If this argument is not
specified, then the internal default template is used.

The template can use the following variables:

=over

=item C<$cpan_rt>

CPAN's request tracker, e.g.:

   https://rt.cpan.org/NoAuth/ReportBug.html?Queue=My-Great-Module

=item C<$email>

User's email address.

=item C<$full_name>

User's full name.

=item C<$github_i>

Github issue, e.g.:

   https://github.com/jd/My-Great-Module/issues

See method C<create_security_md()> for information on how the repo name is generated.

=item C<$module>

=back


=item C<create_security_md(I<NAMED_ARGUMENTS>)>

Creates F<SECURITY.md> in directory C<dir> (see corresponding constructor
argument). The arguments accepted by this method are exactly the same as those accepted by the C<new()> method of L<Software::Security::Policy::Individual>.

However, there are the following defaults:

=over

=item C<maintainer:>

User's full name and email address, e.g.:

   John Doe <jd@cpan.org>

=item C<program>

Module name, see constructor argument C<module>.

=item C<url>

   https://github.com/LOGIN/REPO/blob/main/SECURITY.md

where:

=over

=item I<C<LOGIN>>

User's login name, see constructor argument C<login>.

=item I<C<REPO>>

The repo name is structured as follows:

=over

=item *

The repo name begins with the contents of <prefix()>.

=item *

The rest of the repo name is the module name where the double colons are replaced with hyphens.

=item *

If the constructor argument C<uncapitalise> was I<C<true>>, the latter part of
the repo name is changed to lower case.

=back

=back

=back

To completely disable one of these arguments, set it to C<undef> or an empty string.

=back


=head3 Accessors

=over

=item C<dir()>

Returns the value passed via the constructor argument C<dir> or the default
value C<'.'>.

=item C<email()>

Returns the user's email address.

=item C<full_name()>

Returns the user's full name.

=item C<login()>

Returns the value passed via the constructor argument C<login>.

=item C<module()>

Returns the value passed via the constructor argument C<module>.

=item C<prefix()>

Returns the value passed via the constructor argument C<prefix> or the default
value (empty string).

=item C<uncapitalize()>

Returns the value passed via the constructor argument C<uncapitalize> or the default
value (I<C<false>>).

=back


=head1 AUTHOR

Klaus Rindfrey, C<< <klausrin at cpan.org.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dist-policyfiles at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-PolicyFiles>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

L<dist-policyfiles>,
L<GitHub::Config::SSH::UserData>,
L<Software::Security::Policy::Individual>,
L<Text::Template>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::PolicyFiles


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-PolicyFiles>

=item * Search CPAN

L<https://metacpan.org/release/Dist-PolicyFiles>

=item * GitHub Repository

L<https://github.com/klaus-rindfrey/perl-dist-policyfiles>

=back



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
