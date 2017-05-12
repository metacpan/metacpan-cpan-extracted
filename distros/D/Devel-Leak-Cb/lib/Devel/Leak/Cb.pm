package Devel::Leak::Cb;

use 5.008008;
use common::sense;
m{
use strict;
use warnings;
}x;
=head1 NAME

Devel::Leak::Cb - Detect leaked callbacks

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Devel::Leak::Cb;
    
    AnyEvent->timer( after => 1, cb => cb {
        ...
    });
    
    # If $ENV{DEBUG_CB} is true and callback not destroyed till END, the you'll be noticed

=head1 DESCRIPTION

By default, cb { .. } will be rewritten as sub { .. } using L<Devel::Declare> and will give no additional cost at runtime

When C<$ENV{DEBUG_CB}> will be set, then all cb {} declarations will be counted, and if some of them will not be destroyed till the END stage, you'll be warned

=head1 EXPORT

Exports a single function: cb {}, which would be rewritten as sub {} when C<$ENV{DEBUG_CB}> is not in effect

If C<DEBUG_CB> > 1 and L<Devel::FindRef> is installed, then output will include reference tree of leaked callbacks

=head1 FUNCTIONS

=head2 cb {}

Create anonymous callback

	my $cb = cb {};

=head2 cb name {}

Create named callback with static name (Have no effect without C<$ENV{DEBUG_CB}>)

	my $cb = cb mycallback {};

=head2 cb $name {}

Create named callback with dynamic name (Have no effect without C<$ENV{DEBUG_CB}>)
$name could me only simple scalar identifier, without any special symbols

	my $cb = cb $name {};
	my $cb = cb $full::name {};

=head2 cb 'name' {}

Create named callback with dynamic name (Have no effect without C<$ENV{DEBUG_CB}>)
Currently supported only ' and ". Quote-like operators support will be later

	my $cb = cb 'name' {};
	my $cb = cb "name.$val" {};

=head2 COUNT

	You may call C<Devel::Leak::Cb::COUNT()> Manually to check state. All leaked callbacks will be warned. Noop without C<$ENV{DEBUG_CB}>

=cut

use Devel::Declare ();
use Scalar::Util 'weaken';

our @CARP_NOT = qw(Devel::Declare);
our %DEF;

BEGIN {
	if ($ENV{DEBUG_CB}) {
		my $debug = $ENV{DEBUG_CB};
		*DEBUG = sub () { $debug };
	} else {
		*DEBUG = sub () { 0 };
	}
}


BEGIN {
	if (DEBUG){
		eval { require Sub::Identify;   Sub::Identify->import('sub_fullname'); 1 } or *sub_fullname = sub { return };
		eval { require Sub::Name;       Sub::Name->import('subname');          1 } or *subname      = sub { $_[1] };
		eval { require Devel::Refcount; Devel::Refcount->import('refcount');   1 } or *refcount     = sub { -1 };
		*COUNT = sub () {
			for (keys %DEF) {
				my $d = delete $DEF{$_};
				#print STDERR "Counting $_ [ @$d ]";
				$d->[0] or next;
				my $name = $d->[4] ? $d->[1].'::cb.'.$d->[4] : sub_fullname($d->[0]) || $d->[1].'::cb.__ANON__';
				substr($name,-10) eq '::__ANON__' and substr($name,-10) = '::cb.__ANON__';
				warn "Leaked: $name (refs:".refcount($d->[0]).") defined at $d->[2] line $d->[3]\n".(DEBUG > 1 ? findref($d->[0]) : '' );
			}
		};
	} else {
		*COUNT = sub () {};
	}
	if (DEBUG>1) {
		eval { require Devel::FindRef;  *findref = \&Devel::FindRef::track; 1 } or *findref  = sub { "No Devel::FindRef installed\n" };
	}
}

sub import{
	my $class = shift;
	my $caller = caller;
	Devel::Declare->setup_for(
		$caller,
		{ 'cb' => { const => \&parse } }
	);
	{
		no strict 'refs';
		*{$caller.'::cb' } = sub() { 1 };
	}
}

sub __cb__::DESTROY {
	#print STDERR "destroy $_[0]\n";
	delete($DEF{int $_[0]});
};

our $LASTNAME;

sub remebmer($) {
	$LASTNAME = $_[0];
	return 1;
}

sub wrapper (&) {
	$DEF{int $_[0]} = [ $_[0], (caller)[0..2], $LASTNAME ];
	weaken($DEF{int $_[0]}[0]);
	subname($DEF{int $_[0]}[1].'::cb.'.$LASTNAME => $_[0]) if $LASTNAME;
	$LASTNAME = undef;
	return bless $_[0],'__cb__';
}

sub parse {
	my $offset = $_[1];
	$offset += Devel::Declare::toke_move_past_token($offset);
	$offset += Devel::Declare::toke_skipspace($offset);
	my $name = 'undef';
	my $line = Devel::Declare::get_linestr();
	
	if (
		substr($line,$offset,1) =~ /^('|")/ # '
		and my $len = Devel::Declare::toke_scan_str($offset)
	){
		my $lex = $1;
		my $st = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();
		#warn "Got lex $lex >$st<";
		my $linestr = Devel::Declare::get_linestr();
		if ( $len < 0 or $offset + $len > length($linestr) ) {
			require Carp;
			Carp::croak("Unbalanced text supplied");
		}
		substr($linestr, $offset, $len) = '';
		Devel::Declare::set_linestr($linestr);
		$name = qq{$lex$st$lex};
		
	}
	elsif (my $len = Devel::Declare::toke_scan_word($offset, 1)) {
		my $linestr = Devel::Declare::get_linestr();
		$name = substr($linestr, $offset, $len);
		substr($linestr, $offset, $len) = '';
		Devel::Declare::set_linestr($linestr);
		$offset += Devel::Declare::toke_skipspace($offset);
		$name = qq{'$name'};
	}
	elsif (substr(my $line = Devel::Declare::get_linestr(),$offset,1) eq '$') {
		if (my $len = Devel::Declare::toke_scan_word($offset+1, 1)) {
			my $linestr = Devel::Declare::get_linestr();
			$name = substr($linestr, $offset, $len+1);
			substr($linestr, $offset, $len+1) = '';
			Devel::Declare::set_linestr($linestr);
			$offset += Devel::Declare::toke_skipspace($offset);
			$name = qq{$name};
		} else {
			die("Bad syntax: $line at @{[ (caller 1)[1] ]}");
		}
	}
	
	my $linestr = Devel::Declare::get_linestr();
	if (DEBUG) {
		substr($linestr,$offset,0) = '&& Devel::Leak::Cb::remebmer('.$name.') && Devel::Leak::Cb::wrapper ';
		Devel::Declare::set_linestr($linestr);
	} else {
		substr($linestr,$offset,0) = '&& sub ';
		Devel::Declare::set_linestr($linestr);
	}
	#warn $linestr;
	return;
}

END {
	COUNT();
}

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-leak-cb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Leak-Cb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Leak::Cb

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Leak-Cb>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Devel::Leak::Cb
