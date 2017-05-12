package Function::Override;

use Carp;
use strict;
use vars qw( $Debug $VERSION @EXPORT );

use base qw(Exporter);

$VERSION = '0.03';
@EXPORT = qw(override);

$Debug = $ENV{PERL_FUNCTION_OVERRIDE_DEBUG} || 0 unless defined $Debug;

sub override {
    my($sym, $callback, $pkg) = @_;
    $pkg = caller() unless defined $pkg;
    &_override_function($sym, $callback, $pkg);
};

sub fill_protos {
  my $proto = shift;
  my ($n, $isref, @out, @out1, $seen_semi) = -1;
  while ($proto =~ /\S/) {
    $n++;
    push(@out1,[$n,@out]) if $seen_semi;
    push(@out, $1 . "{\$_[$n]}"),   next if $proto =~ s/^\s*\\([\@%\$\&])//;
    push(@out, "\$_[$n]"),          next if $proto =~ s/^\s*([*\$&_])//;
    push(@out, "\@_[$n..\$#_]"),    last if $proto =~ s/^\s*(;\s*)?\@//;
    $seen_semi = 1, $n--,           next if $proto =~ s/^\s*;//; # XXXX ????
    die "Unknown prototype letters: \"$proto\"";
  }
  push(@out1,[$n+1,@out]);
  @out1;
}

sub write_invocation {
  my ($core, $call, $name, @argvs) = @_;
  if (@argvs == 1) {		# No optional arguments
    my @argv = @{$argvs[0]};
    shift @argv;
    return "\t" . one_invocation($core, $call, $name, @argv) . ";\n";
  } else {
    my $else = "\t";
    my (@out, @argv, $n);
    while (@argvs) {
      @argv = @{shift @argvs};
      $n = shift @argv;
      push @out, "$ {else}if (\@_ == $n) {\n";
      $else = "\t} els";
      push @out, 
          "\t\treturn " . one_invocation($core, $call, $name, @argv) . ";\n";
    }
    push @out, <<EOC;
	}
	die "$name(\@_): Do not expect to get ", scalar \@_, " arguments";
EOC
    return join '', @out;
  }
}

sub one_invocation {
  my ($core, $call, $name, @argv) = @_;
  local $" = ', ';
  return qq{$call(@argv)};
}

sub _override_function {
    my($sub, $callback, $pkg) = @_;
    my($name, $code, $sref, $real_proto, $proto, $core, $call);
    my $ini = $sub;

    $sub = "${pkg}::$sub" unless $sub =~ /::/;
    $name = $sub;
    $name =~ s/.*::// or $name =~ s/^&//;
    print "# _override_function: sub=$sub pkg=$pkg name=$name\n" if $Debug;
    croak "Bad subroutine name for Function::Override: $name" 
      unless $name =~ /^\w+$/;
    if (defined(&$sub)) {	# user subroutine
	$sref = \&$sub;
	$proto = prototype $sref;
	$call = '&$sref';
    } elsif ($sub eq $ini) {	# Stray user subroutine
	die "$sub is not a Perl subroutine" 
    } else {			# CORE subroutine
        $proto = eval { prototype "CORE::$name" };
	die "$name is neither a builtin, nor a Perl subroutine" 
	  if $@;
	die "Cannot override the non-overridable builtin '$name'"
	  if not defined $proto;
	$core = 1;
	$call = "CORE::$name";
    }
    if (defined $proto) {
      $real_proto = " ($proto)";
    } else {
      $real_proto = '';
      $proto = '@';
    }
    $code = <<EOS;
sub$real_proto {
	local(\$", \$!) = (', ', 0);
        \$callback->(\@_);
EOS
    my @protos = fill_protos($proto);
    $code .= write_invocation($core, $call, $name, @protos);
    $code .= "}\n";
    {
      no strict 'refs'; # to avoid: Can't use string (...) as a symbol ref ...
      $code = <<"CODE";
package $pkg;
$code
CODE

      print $code if $Debug;

      $code = eval($code);
      die if $@;
      local($^W) = 0;   # to avoid: Subroutine foo redefined ...
      *{$sub} = $code;
    }
}

1;

__END__

=head1 NAME

Function::Override - Add callbacks to existing functions.


=head1 SYNOPSIS

    use Function::Override;
    use Carp;

    BEGIN {
         override('open', 
                  sub { 
                      my $wantarray = (caller(1))[5];
                      carp "You didn't check if open() succeeded"
                          unless defined $wantarray;
                  }
                 );
    }

    open(FILE, $filename);      # This produces a warning now.
    print <FILE>;
    close FILE;
                              

=head1 DESCRIPTION

** THIS IS ALPHA CODE! **

Function::Override provides a way to conveniently add code to existing
functions.

You may wrap both user-defined functions and overridable CORE
operators in this way.  Although if you override a CORE function its
usually wise to do it in a BEGIN block so Perl will see it.


=head1 TODO

Add a more flexible callback system offering pre and post function routines.

Offer more information to the callback, such as the subroutine name.

Merge Fatal.pm and possiblely Memoize.pm.


=head1 ENVIRONMENT

=over 4

=item PERL_FUNCTION_OVERRIDE_DEBUG

If true, this flag turns on debugging output.

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> but its really 99.99% Fatal.pm by 
Lionel.Cons@cern.ch


=head1 SEE ALSO

L<Fatal>

=cut
