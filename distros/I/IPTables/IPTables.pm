####################################################################
## The little hampster grew humps, and wrote this....             ##
## Copyright (c) 2001 Theo Zourzouvillys <theo@crazygreek.co.uk>  ##
## Includes code from netfilter (netfilter.samba.org)             ##
####################################################################
#       .Copyright (C)  2000-2001 Theo Zourzouvillys
#       .Created:       26/09/2001
#       .Contactid:     <theo@crazygreek.co.uk>
#       .Url:           http://theo.me.uk
#       .Authors:       Theo Zourzouvillys
#	.ID:            $Id: IPTables.pm,v 1.10 2002/04/05 19:58:35 theo Exp $

## You're lucky if it even installs dammit ;)

package IPTables;
use strict;
#$^W = 1;

use Carp qw(cluck);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD %EXPORT_TAGS);

require Exporter;
require DynaLoader;
require AutoLoader;
sub dl_load_flags { 0x01 };
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(IFNAMSIZ IPT_TABLE_MAXNAMELEN IPT_F_FRAG IPT_F_MASK IPT_INV_VIA_IN 
				IPT_INV_VIA_OUT IPT_INV_TOS IPT_INV_SRCIP IPT_INV_DSTIP IPT_INV_FRAG
				IPT_INV_PROTO IPT_INV_MASK list_matches match_help target_help list_targets);
%EXPORT_TAGS = (constants => \@EXPORT_OK);

$VERSION = '0.05';

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    cluck "& not defined" if $constname eq 'constant';

    my $val = constant($constname, @_ ? $_[0] : 0);

    if ($! != 0) {
        if ($! =~ /Invalid/) {  
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        } else {
            cluck "Your vendor has not defined ".
                  " IPTables macro $constname";
        }
    }

    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap IPTables $VERSION;

##### Public!

sub new
{
    my ($class, $name) = @_;
    my $self = { };
    bless $self, ref($class) || $class;
    return $self->_init($name);
}

sub first_chain
{
	return iptc_first_chain($_[0]->{_handle});
}

sub next_chain
{
	return iptc_next_chain($_[0]->{_handle});
}

sub builtin
{
	return iptc_builtin($_[0]->{_handle}, $_[1]);
}

sub get_policy
{
	return iptc_get_policy($_[0]->{_handle}, $_[1]);
}

sub first_rule
{
	return iptc_first_rule($_[0]->{_handle}, $_[1]);
}

sub print_num
{
	return _print_num($_[1]);
}

sub commit
{
	printf("Commiting\n");
	my $ret =  iptc_commit($_[0]->{_handle}, $_[1]);
	$_[0]->_init($_[1]);
	return $ret;
}

sub delete_entry
{
	my $h = shift;
	my $chain = shift;
	my $rulenum = shift;
	return _delete_entry($h->{_handle}, $h->{_table}, $chain, $rulenum);
}

sub reset_counter
{
	my $h = shift;
	my $chain = shift;
	return _reset_counter($h->{_handle}, $chain);
}

sub set_policy
{
	my $h = shift;
	my $chain = shift;
	my $policy = shift;
	return _set_policy($h->{_handle}, $chain, $policy);
}

sub add_entry
{
	my $h = shift;
	my $chain = shift;
	my $src = shift;
	my $dst = shift;
	my $proto = shift;
	my $tojump = shift;

	my $match = shift;

	my (@args, $arg) = undef;

	while ($arg = shift)
	{
		my @arg = @{$arg};
		push(@args, "--${arg[0]}");
		push(@args, $arg[1]);
	}


	# h, tablename, chain, src, dst, proto, tojump
	if ($match eq undef)
	{
		return _add_entry($h->{_handle}, $h->{_table}, $chain, $src, $dst, $proto, $tojump);
	} else {
		return _add_entry($h->{_handle}, $h->{_table}, $chain, $src, $dst, $proto, $tojump, $match, @args);
	}
}

sub list_matches
{
	my @mod = ();
	opendir(DIR, '/lib/iptables');
	while (my $file = readdir(DIR))
	{
		next unless ($file =~ /^libipt_(\w+)\.so$/);
		my @opts = get_match_options($1);
		if ($opts[0] ne "-1-")
		{
			push(@mod, [$1, @opts]);
		}
	}
	return @mod;
}

sub list_targets
{
	my @mod = ();
	opendir(DIR, '/lib/iptables');
	while (my $file = readdir(DIR))
	{
		next unless ($file =~ /^libipt_(\w+)\.so$/);
		my @opts = get_target_options($1);
		if ($opts[0] ne "-1-")
		{
			push(@mod, [$1, @opts]);
		}
	}
	return @mod;
}

sub match_help
{
	return undef unless(get_match_help($_[0]))
}

sub target_help
{
	return undef unless(get_target_help($_[0]))
}


#### Private

sub _init
{
    my ($self, $name) = @_;
    $self->{_handle} = _init_xs($name) or return;
	$self->{_table} = $name;
    return $self;
}


sub DESTROY
{
    my ($self) = @_;
##    $self->close();
}



__END__

