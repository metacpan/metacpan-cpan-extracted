#################################################################
#
#   Hook::Filter::Rule - A filter rule
#
#   $Id: Rule.pm,v 1.7 2008/06/09 21:04:08 erwan_lemonnier Exp $
#
#   060301 erwan Created
#   070516 erwan Small POD and layout fixes
#   070524 erwan Used BEGIN instead of INIT
#   080609 erwan Updated POD
#

package Hook::Filter::Rule;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Symbol;
use Module::Pluggable search_path => ['Hook::Filter::Plugins'], require => 1;

our $VERSION='0.04';

#----------------------------------------------------------------
#
#   load test functions from plugins
#

BEGIN {

    my %TESTS;

    foreach my $plugin (Hook::Filter::Rule->plugins()) {
	my @tests = $plugin->register();
	# TODO: test that @tests is an array of strings. die with BUG:

	foreach my $test ($plugin->register()) {
	    if (exists $TESTS{$test}) {
		croak "invalid plugin function: test function [$test] exported by plugin [$plugin] is already exported by an other plugin.";
	    }
	    *{ qualify_to_ref($test,"Hook::Filter::Rule") } = *{ qualify_to_ref($test,$plugin) };
	    $TESTS{$test} = 1;
	}
    }
}

#----------------------------------------------------------------
#
#   new - build a new filter rule
#

sub new {
    my($pkg,$rule) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = bless({},$pkg);

    if (!defined $rule || ref \$rule ne "SCALAR" || scalar @_ != 2) {
	shift @_;
	croak "invalid parameter: Hook::Filter::Rule->new expects one string describing a filter rule, but got [".Dumper(@_)."].";
    }

    $self->{RULE} = $rule;

    return $self;
}

#----------------------------------------------------------------
#
#   rule - accessor for the rule
#

sub rule {
    return $_[0]->{RULE};
}

#----------------------------------------------------------------
#
#   source - where the rule came from (used in error messages only)
#

sub source {
    my($self,$orig) = @_;

    if (!defined $orig || ref \$orig ne "SCALAR" || scalar @_ != 2) {
	shift @_;
	croak "invalid parameter: Hook::Filter::Rule->source expects one string, but got [".Dumper(@_)."].";
    }

    $self->{SOURCE} = $orig;
}

#----------------------------------------------------------------
#
#   eval - evaluate a rule. return either true or false
#

sub eval {
    my $self = shift;
    my $rule = $self->{RULE};

    my $res = eval $rule;
    if ($@) {
	# in doubt, let's assume we are not filtering anything, ie allow function calls as if we were not here
	warn "WARNING: invalid Hook::Filter rule [$rule] ".
	    ( (defined $self->{SOURCE})?"from file [".$self->{SOURCE}."] ":"")."caused error:\n".
	    "[".$@."]. Assuming this rule returned true.\n";
	return 1;
    }

    return ($res)?1:0;
}

1;

__END__

=head1 NAME

Hook::Filter::Rule - A hook filter rule

=head1 DESCRIPTION

A filter rule is a string containing a perl expression that evaluates to
either true or false.

A rule may contain calls to functions exported by any module under
C<< Hook::Filter::Plugins:: >>.

=head1 SYNOPSIS

    use Hook::Filter::Rule;

    my $rule = Hook::Filter::Rule->new("1");
    if ($rule->eval) {
	print "just now, the rule [".$rule->rule."] is true\n";
    }

=head1 INTERFACE

=over 4

=item C<< my $r = new($rule) >>

Return a new C<Hook::Filter::Rule> created from the string C<$rule>. C<$rule>
is a valid line of perl code that should return either true or false when
eval-ed. It can contain calls to any of the functions exported by the plugin modules
located under C<< Hook::Filter::Plugins:: >>.

=item C<< $r->eval() >>

Eval this rule. Return 0 if the rule eval-ed to false. Return 1 if the rule eval-ed
to true, or if the rule died/croaked.

If the rule dies/croaks/confesses while being eval-ed, a perl warning is
thrown and the rule is assumed to return true (fail-safe). The warning
contains details about the error message, the rule itself and where it
comes from (as specified with C<< source() >>).

=item C<< $r->source($message) >>

Specify the origin of this rule. If the rule was parsed from a rule file,
C<$message> should be the path to this file. This is used in the warning
message emitted when a rule dies during C<< eval() >>.

=item C<< $r->rule() >>

Return the rule's string (C<$rule> in C<< new() >>).

=back

The following functions are exported by the default plugin library Hook::Filter::Plugin::Library:

=over 4

=item C<< subname >>

=item C<< arg >>

=item C<< from >>

=back

=head1 DIAGNOSTICS

=over 4

=item C<< use Hook::Filter::Rule >> croaks if a plugin module tries to export a function name
that is already exported by an other plugin.

=item C<< Hook::Filter::Rule->new($rule) >> croaks if C<$rule> is not a scalar.

=item C<< $rule->eval() >> will emit a perl warning if the rule dies when eval-ed.

=item C<< $rule->source($text) >> croaks if C<$text> is not a scalar.

=back

=head1 BUGS AND LIMITATIONS

See Hook::Filter

=head1 SEE ALSO

See Hook::Filter, Hook::Filter::RulePool, Hook::Filter::Hooker, Hook::Filter::Plugins::Library.

=head1 VERSION

$Id: Rule.pm,v 1.7 2008/06/09 21:04:08 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Hook::Filter.

=cut
