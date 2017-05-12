
package HTML::WebMake::CGI::Lib;

use strict;
use HTML::Entities;
use HTML::WebMake::Util;

use vars	qw{ @ISA };

@ISA = qw();

###########################################################################

sub mksafe {
  local($_) = shift;
  if (!defined $_) { return undef; }

  s/\0/_/gs;		# strip NULs
  s/[^-=_+\[\]\@\#,.\/:\~%^\(\)\{\}A-Za-z0-9 ]/_/gs;
  $_;
}

sub mksafepath {
  local($_) = shift;
  if (!defined $_) { return undef; }

  $_ = mksafe($_);
  s/[^-_+\@,.\/:%A-Za-z0-9 ]/_/gs;
  s,^\/+,,gs;		# //foo -> foo
  s,\/\/+,/,gs;		# foo//bar -> foo/bar
  1 while s,^\.\/+,,gs;	# strip ./././foo
  s,[^/]+/+\.\./+,,gs;	# strip ..s
  s,\.\./+,,gs;		# strip any leftover ..s
  s,^\.\.$,.,gs;	# ".." = "."
  $_;
}

sub mksafepathlist {
  local($_) = shift;
  if (!defined $_) { return undef; }

  my @new = ();
  foreach my $item (split (/\|/, $_)) {
    next if ($item eq '');
    push (@new, mksafepath ($item));
  }
  return join ('|', @new);
}

sub is_authorised {
  my ($q) = @_;

  my $auth = $q->auth_type();
  my $user = $q->remote_user();
  if (defined $auth && defined $user) { return 1; }

  warn "unauthorised access from ".$q->remote_host()."\n";
  return 0;
}

1;
