#{
#	package IPTables;
#	use IPTables::IPv6::Toplevel;
#
#	%IPv6;
#	tie(%IPv6, 'IPTables::IPv6::Toplevel');
#}

package IPTables::IPv6;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.98';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined IPTables macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap IPTables::IPv6 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

IPTables::IPv6 - Perl module for manipulating iptables rules for the IPv6 protocol

=head1 SYNOPSIS

  use IPTables::IPv6;
  
  $table = IPTables::IPv6::init('tablename');

  %IPTables::IPv6 = (
      filter => {
		  INPUT => {
		  	     rules => [
			     		{
					  source => '2001::/16',
					  jump => 'ACCEPT'
					}
				      ],
			     pcnt => 50000,
			     bcnt => 1000000,
			     policy => 'DROP'
			   }
		}
  );

=head1 DESCRIPTION

This package provides a nice interface to the IP Tables control API that fairly
closely parallels the C API exported in libiptc for manipulating firewalling
and forwarding rules for IPv6 packets. Also, a tied multilayer data structure
has been built, allowing the tables, chains, rules and fields to be
manipulated in a more natural fashion.

The module will be built with a default library path built into it. That
can be overridden using the IPT_MODPATH environment variable. If your
script is being called suid root, you may want to do
C<delete $ENV{IPT_MODPATH};> to ensure that someone isn't subverting
your script. Make sure you do this before you C<use IPTables::IPv6;> to
ensure that it never loads from an unapproved path.

=head1 METHODS

Most methods will return 1 for success, or 0 for failure (and on failure, set
$! to a string describing the reason for the failure). Unless otherwise noted,
you can assume that all methods will use this convention.

=head2 Initialization

=over

=item $table = IPTables::IPv6::init('tablename')

This sets up the connection to the kernel-level netfilter subsystem.
C<tablename> corresponds to the name of a table (C<filter>, C<nat>, C<mangle>,
or C<dropped>) to manipulate. The call returns an object of type
IPTables::IPv6::Table, which all the other methods are to be called against,
if the named table exists. If it does not exist, C<undef> will be returned.

=back

=head2 Chain Operations

=over

=item $is_builtin = $table-E<gt>builtin('chainname')

This checks if the chain C<chainname> is built into the current table. The
method will return 1 if C<chainname> is a built-in chain, or 0 if it is not.

=item $success = $table-E<gt>create_chain('chainname')

This attempts to create the chain C<chainname>.

=item $success = $table-E<gt>delete_chain('chainname')

This attempts to delete the chain C<chainname>.

=item ($policy, $pcnt, $bcnt) = $table-E<gt>get_policy('chainname')

This returns an array containing the default policy, and the number of packets
and bytes which have reached the default policy, in the chain C<chainname>. If
C<chainname> does not exist, or if it is not a built-in chain, an empty array
will be returned, and $! will be set to a string containing the reason.

=item $refcnt = $table-E<gt>get_references('chainname')

This returns the reference count for the chain C<chainname> if it exists and
is a user-defined chain. If C<chainname> does not exist, or is a built-in
chain, -1 will be returned, and $! will be set to a string containing the
reason.

=item $is_chain = $table-E<gt>is_chain('chainname')

This checks to verify that the chain C<chainname> exists in the current table.
The method will return 1 if C<chainname> is a chain, 0 if not.

=item @chains = $table-E<gt>list_chains()

In array context, this method returns an array containing names of all
existing chains in the table that C<$table> points to. In scalar context,
returns the number of chains in the table.

=item $success = $table-E<gt>rename_chain('oldname', 'newname')

This attempts to rename the chain C<oldname> to C<newname>.

=item $success = $table-E<gt>set_policy('chainname', 'target')

=item $success = $table-E<gt>set_policy('chainname', 'target', {pcnt =E<gt> count, bcnt =E<gt> count})

This attempts to set the default target for the chain C<chainname> to
C<target>. It also allows the packet and byte counters on a chain to be set
using the (optional) third argument. Those values must be passed as a hash
ref, as shown.

=back

=head2 Rule Operations

=over

=item $success = $table-E<gt>append_entry('chainname', $hashref)

This attempts to append the rule described in the hash referenced by
C<$hashref> to the chain C<chainname>.

=item $success = $table-E<gt>delete_entry('chainname', $hashref)

This attempts to delete a rule matching that described in the hash referenced
by C<$hashref> from the chain C<chainname>.

=item $success = $table-E<gt>delete_num_entry('chainname', $rulenum)

This attempts to delete the rule C<$rulenum> from the chain C<chainname>.

=item $success = $table-E<gt>flush_entries('chainname')

This deletes all rules from the chain C<chainname>.

=item $success = $table-E<gt>insert_entry('chainname', $hashref, $rulenum)

This attempts to insert the rule described in the hash referenced by
C<$hashref> at index C<$rulenum> in the chain C<chainname>.

=item @rules = $table-E<gt>list_rules('chainname')

When called in array context, this method returns an array of hash
references, which contain descriptions of each rule in the chain
C<chainname>. In scalar context, returns the number of rules in the chain.

Note that if the chain C<chainname> does not exist, an empty list will be
returned, as will listing an empty chain. Be sure to verify that the chain
exists I<before> you try to list the rules.

=item $success = $table-E<gt>replace_entry('chainname', $hashref, $rulenum)

This attempts to replace the rule at index C<$rulenum> in the chain
C<chainname> with the rule described in the hash referenced by C<$hashref>.

=item $success = $table-E<gt>zero_entries('chainname')

This zeroes all packet counters in the chain C<chainname>.

=back

=head2 Cleanup

=over

=item $success = $table-E<gt>commit()

This attempts to commit all changes made to the IP chains in the table that
C<$table> points to, and closes the connection to the kernel-level netfilter
subsystem. If you wish to apply your changes back to the kernel, you must
call this.

=back

=head1 RULE STRUCTURE

The rules in the libiptc interface are expressed as C<struct ipt_entry>s.
However, I have decided to express the rules as hashes. The rules are passed
around as hash references, and may contain the following fields:

=over

=item source

The source address of a packet. This will appear in one of the following forms:

	ip:v6:add::re:ss
	ip:v6:add::rs:ss/maskwidth
	ip:v6:add::re:ss/ip:v6:ne::tma:sk

It may be prefixed with a '!', to indicate the inverse sense of the address
(i.e., match anything EXCEPT the address or address range specified).

=item destination

The destination address of a packet. It will appear in one of the same forms as
C<source> (see above).

=item in-interface

The network device which received the packet. Some chains cannot accept a rule
with C<in-interface> set (such as the C<PREROUTING> chain). This may show up
as a full interface name (such as C<eth0>), or as a wildcarded interface name
(such as C<eth+>, where C<+> is the wildcard character, which can only be used
at the end of a wildcarded interface string). It may be prefixed with a '!', to
indicate the inverse sense of the interface (i.e., match anything EXCEPT the
interface specified).

=item out-interface

The network device that a packet will be sent out via. Some chains cannot accept
a rule with C<out-interface> set (such as the C<INPUT> chain). The format is the
same as that for C<in-interface> (see above).

=item protocol

The name of the protocol of an incoming packet. It may be prefixed with a '!',
to indicate the inverse sense of the protocol (i.e., match anything EXCEPT this
protocol).

=item jump

The target or chain to jump to if the rule matches.

=item pcnt/bcnt

The number of packets and bytes that have matched this rule since the rule was
put in place, or since its counters were last zeroed.

=item matches

An array reference, containing a list of all the match modules which are to be
used as part of the rule. Any match qualifier other than a protocol match
module - i.e., C<tos>, C<mport>, C<state>, etc., must be specified with this
option, or any fields that belong to them will not be honored.

=item [target]-target-raw

This contains, as a string, the raw target data for a rule, if the needed
module can't be found. I<[target]> should be the name of the target. There
will, of course, only be one of these per rule (as each rule can only have one
target).

=item [match]-match-raw

This contains, as a string, the raw match data for a rule, if the needed
module can't be found. I<[match]> should be the name of the match. There can be
more than one of these in one rule. If a match is specified in C<matches>,
and no match module is available, raw data must be provided.

=back

=head1 MODULE-SPECIFIC RULE OPTIONS

Each module, for protocols, non-protocol matches, and non-standard targets,
has specific keys associated with specific options.

This material will be added later on, once I'm sure everything is working
as it should be.

=head1 AUTHOR

Derrik Pates, dpates@dsdk12.net

=head1 SEE ALSO

L<iptables(8)>.

=cut
