#################################################################
#
#   Hook::Filter::Hooker - Wrap subroutines in a firewalling closure
#
#   $Id: Hooker.pm,v 1.8 2007/05/24 14:58:09 erwan_lemonnier Exp $
#
#   060302 erwan Created
#   070516 erwan Use the rule pool
#

package Hook::Filter::Hooker;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Symbol;
use base qw(Exporter);
use Hook::Filter::RulePool qw(get_rule_pool);

our @EXPORT = qw();
our @EXPORT_OK = qw( get_caller_package
		     get_caller_file
		     get_caller_line
		     get_caller_subname
		     get_subname
		     get_arguments
		     filter_sub
		     );



use vars qw( $CALLER_PACKAGE
	     $CALLER_FILE
	     $CALLER_LINE
	     $CALLER_SUBNAME
	     $SUBNAME
	     @ARGUMENTS );

# singleton instance of Hook::Filter::RulePool
my $pool = get_rule_pool();

# a hash whose keys are the fully qualified names of all filtered
# subroutines, to avoid filtering one twice
my %subs;

#----------------------------------------------------------------
#
#   accessors for use in Hook::Filter::Plugins:: modules
#

sub get_caller_package   { return $CALLER_PACKAGE; };
sub get_caller_file      { return $CALLER_FILE;    };
sub get_caller_line      { return $CALLER_LINE;    };
sub get_caller_subname   { return $CALLER_SUBNAME; };
sub get_subname          { return $SUBNAME;        };
sub get_arguments        { return @ARGUMENTS;      };

#----------------------------------------------------------------
#
#   filter_sub - build a filter closure wrapping calls to the provided sub
#

sub filter_sub {
    my $subname = shift;

    if (!defined $subname || ref \$subname ne "SCALAR" || scalar @_) {
	shift @_;
	croak "invalid parameter: Hook::Filter::Hooker->filter_sub expects a subroutine name, but got [".Dumper($subname,@_)."].";
    }

    if ($subname !~ /^(.+)::([^:]+)$/) {
	croak "invalid parameter: [$subname] is not a valid subroutine name (must include package name).";
    }

    my ($pkg,$func) = ($1,$2);

    # check whether subroutine is already filtered, and skip if so
    return if (exists $subs{$subname});

    my $filtered_func = *{ qualify_to_ref($func,$pkg) }{CODE};

    # create the closure that will replace $func in package $pkg
    my $filter = sub {
	my (@args) = @_;

	# TODO: looking at source for Hook::WrapSub, it might be a good idea to copy/paste some of its code here, to build a valid caller stack
	# TODO: look at Hook::LexWrap and fix so that caller() work in subroutines

	# set global variables
	$CALLER_PACKAGE  = (caller(0))[0];
	$CALLER_FILE     = (caller(0))[1];
	$CALLER_LINE     = (caller(0))[2];
	$CALLER_SUBNAME  = (caller(1))[3] || "";
	$SUBNAME         = $subname;
	@ARGUMENTS       = @args;

	# evaluate all rules. if true is returned, forward the call
	if ($pool->eval_rules) {
	    if (wantarray) {
		my @results = $filtered_func->(@args);
		return @results;
	    } else {
		my $result = $filtered_func->(@args);
		return $result;
	    }
	}

	# the call was blocked. fake a return value (ugly.)
	if (wantarray) {
	    return ();
	}
	return;
    };

    # keep track of already hooked subroutines
    $subs{$subname} = 1;

    # replace $package::$func with our closure
    no strict 'refs';
    no warnings;

    *{ qualify_to_ref($func,$pkg) } = $filter;
}

1;

__END__

=head1 NAME

Hook::Filter::Hooker - Wrap subroutines in a firewalling closure

=head1 DESCRIPTION

This module is used internaly by Hook::Filter to generate an anonymous
sub that is wrapped around each filtered subroutine and either forwards
the call to the subroutine or block it and spoofs return values (undef or
an empty list depending on context).

=head1 SYNOPSIS

    use Hook::Filter::Hooker;

    my $hooker = new Hook::Filter::Hooker();

    $hooker->filter_sub("My::Package");

    # mylog is declared in the current package
    $hooker->filter_sub("mylog");

=head1 INTERFACE

C<Hook::Filter::Hooker> exports no functions by default. But the following functions
can be explicitly imported upon using C<Hook::Filter::Hooker>:

=over 4

=item C<< $hooker->filter_sub($subname) >>

Add a filter around the subroutine C<$subname>. I<$subname> must either be a fully qualified
function name, or the name of a function located in the current package.

All calls to C<< $subname >> will thereafter be redirected
to a wrapper closure that will evaluate all the rules registered in
C<Hook::Filter::RulePool> using the method C<eval()> on the pool.
If C<eval()> returns true, the call is forwarded, otherwise it is
blocked.

=back

The following class functions are to be used by modules under
C<Hook::Filter::Plugins::> that implement specific test functions
for use in filter rules.

Any use of these functions in a different context than
inside a plugin implementation is guaranteed
to return only garbage.

See C<Hook::Filter::Plugins::Library> for a usage example.

=over 4

=item C<get_caller_package()>

Return the name of the package calling the filtered subroutine.

=item C<get_caller_file()>

Return the name of the file calling the filtered subroutine.

=item C<get_caller_line()>

Return the line number at which the filtered subroutine was called.

=item C<get_caller_subname()>

Return the complete name (package+name) of the subroutine calling the filtered subroutine.
If the subroutine was called directly from the main namespace, return an empty string.

=item C<get_subname()>

Return the complete name of the filtered subroutine for which the rules
are being eval-ed.

=item C<get_arguments()>

Return the list of arguments that would be passed to the filtered subroutine.

=back

=head1 DIAGNOSTICS

=over 4

=item C<< $hook->filter_sub(I<$pkg>,I<$func>) >> croaks when passed invalid arguments.

=item The closure wrapping all filtered subroutines emits a perl warning when a rule dies upon being eval-ed.

=back

=head1 BUGS AND LIMITATIONS

See Hook::Filter

=head1 SEE ALSO

See Hook::Filter, Hook::Filter::Rule, Hook::Filter::RulePool, Hook::Filter::Plugins::Library.

=head1 VERSION

$Id: Hooker.pm,v 1.8 2007/05/24 14:58:09 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>.

=head1 LICENSE

See Hook::Filter.

=cut



