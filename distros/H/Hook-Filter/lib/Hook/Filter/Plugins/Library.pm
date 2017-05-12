#################################################################
#
#   Hook::Filter::Plugin::Library - Usefull functions for writing filter rules
#
#   $Id: Library.pm,v 1.4 2007/05/24 14:52:37 erwan_lemonnier Exp $
#
#   060302 erwan Created
#   070516 erwan Removed from_xxx(), added from(), arg() and subname()
#

package Hook::Filter::Plugins::Library;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Hook::Filter::Hooker;# qw( get_caller_subname get_caller_package get_subname get_arguments );

#----------------------------------------------------------------
#
#   register - return a list of the tests available in this plugin
#

sub register {
    return qw(from arg subname);
}

#----------------------------------------------------------------
#
#   from - returns the fully qualified name of the caller
#

sub from {
    return Hook::Filter::Hooker::get_caller_subname();
}

#----------------------------------------------------------------
#
#   arg - return the n-ieme argument passed to the filtered subroutine
#

sub arg {
    my $pos = shift;
    croak "invalid rule: function arg expects a number, got: ".Dumper($pos,@_) if (!defined $pos || @_ || $pos !~ /^\d+$/);
    my @args = Hook::Filter::Hooker::get_arguments();
    return $args[$pos];
}

#----------------------------------------------------------------
#
#   subname - return the fully qualified name of the called subroutine
#

sub subname {
    return Hook::Filter::Hooker::get_subname();
}

1;

__END__

=head1 NAME

Hook::Filter::Plugin::Library - Usefull functions for writing filter rules

=head1 DESCRIPTION

A library of functions usefull when writing filter rules.
Those functions should be used inside C<Hook::Filter> rules, and nowhere else.

=head1 SYNOPSIS

Exemples of rules using test functions from C<Hook::Filter::Plugin::Location>:

    # allow all subroutine calls made from inside function 'do_this' from package 'main'
    from =~ /main::do:this/

    # the opposite
    from !~ /main::do:this/

    # the called subroutine matches a given name
    subname =~ /foobar/

    # the 2nd argument of passed to the subroutine is a string matching 'bob'
    defined arg(1) && arg(1) =~ /bob/

=head1 INTERFACE - TEST FUNCTIONS

The following functions are only exported into C<Hook::Filter::Rule> and
shall only be used inside filter rules.

=over 4

=item C<from>

Return the fully qualified name of the caller of the filtered subroutine.

Example:

    use Hook::Filter hook => 'foo';
    use Hook::Filter::RulePool qw(get_rule_pool);

    sub foo {}
    sub bar1 { foo; }
    sub bar2 { foo; }

    # add a rule to allow only calls to foo from within bar1 and bar2:
    get_rule_pool->add_rule("from =~ /bar\d$/");

    foo();  # foo is not called
    bar1(); # foo is called
    bar2(); # foo is called

=item C<subname>

Return the fully qualified name of the filtered subroutine being called.

Example:

    use Hook::Filter hook => [ 'foo', 'bar' ];
    use Hook::Filter::RulePool qw(get_rule_pool);

    sub foo {};
    sub bar {};

    # add a rule to allow only calls to foo:
    get_rule_pool->add_rule("subname eq 'main::foo'");

    foo();  # foo is called
    bar();  # bar is not called

=item C<< arg($pos) >>

Return the argument at position C<$pos> in the list of arguments to be
passed to the filtered subroutine.

Example:

    use Hook::Filter hook => 'debug';

    sub debug {
        print $_[1]."\n" if ($_[0] <= $VERBOSITY);
    }

    # allow calls to debug only if the text matches the name 'bob'
    get_rule_pool->add_rule("arg(1) =~ /bob/");

    debug(1,"bob did that");      # debug is called
    debug(3,"david thinks this"); # debug is not called

=back

=head1 INTERFACE - PLUGIN STRUCTURE

Like all plugins under C<Hook::Filter::Plugins>, C<Hook::Filter::Plugins::Library> implements the class method C<< register() >>:

=over 4

=item C<< register() >>

Return the names of the test functions implemented in C<Hook::Filter::Plugins::Location>. Used
internally by C<Hook::Filter::Rule>.

=back

=head1 DIAGNOSTICS

No diagnostics. Any bug in those test functions would cause a warning emitted by C<Hook::Filter::Rule::eval()>.

=head1 BUGS AND LIMITATIONS

See Hook::Filter

=head1 SEE ALSO

See Hook::Filter, Hook::Filter::Rule, Hook::Filter::RulePool, Hook::Filter::Hooker.

=head1 VERSION

$Id: Library.pm,v 1.4 2007/05/24 14:52:37 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>.

=head1 LICENSE

See Hook::Filter.

=cut



