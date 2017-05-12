#!/usr/bin/perl -w

package Dev::Bollocks;

use Math::String;
@ISA = qw(Math::String);

use vars qw($VERSION $accuracy $precision $fallback $rnd_mode);
$VERSION = 0.06;
require  5.008001;
use strict;

$accuracy = undef;
$precision = undef;
$fallback = 0;
$rnd_mode = 'even';

use overload
'cmp'   =>      sub { $_[2] ?
              $_[1] cmp Math::String::bstr($_[0]) :
              Math::String::bstr($_[0]) cmp $_[1] },
# can modify arg of ++ and --, so avoid a new-copy for speed
'++'    =>      sub { Math::BigInt::badd($_[0],Math::BigInt->bone()) },
'--'    =>      sub { Math::BigInt::badd($_[0],Math::BigInt->bone('-')) },

;         

my $CALC;
my $bollocks;

BEGIN
  {
  $CALC = Math::BigInt->config()->{lib};

  # if we did this for every new() instead of in BEGIN, we would waste even
  # more resources. But we can't wait for management all day...
    my $verbs = [ qw/
	aggregate
	administrate
	accelerate 
	architect
	benchmark
	brand
	build
	bully
	cluster
	create
	coordinate
	consolidate
	compete
	conquer
	customize
	cultivate
	deliver
	deploy
	develop
	disintermediate
	disseminate
	differentiate
	drive
	e-enable
	embrace
	empower
	enable
	engage
	engineer
	enhance
	entrench 
	envisioneer
	establish
	evolve
	expedite
	exploit
	extend
	facilitate
	fashion
	foster
	generate
	grow
	harness
	harvest
	improve
	implement
	incentivize
	incubate
	industrialize
	innovate
	introduce
	integrate
	initiate
	iterate
	lead
	leverage
	network
	negotiate
	market
	maintain
	maximize
	mesh
	monetize
	morph
	optimize
	orchestrate
	participate
	pursue
	promote
	reintermediate
	reinvent
	repurpose
	restore
	revolutionize
	scale
	seize
	strategize
	streamline
	supply
	syndicate
	synergize
	synthesize
	target
	transform
	transition
	unleash
	utilize
	visualize 
     /];
    my $adverbs = [ qw(
	adaptively
	authoritatively
	administratively
	advantageously
	ambassadorially
	apprehensively
	appropriately
	assertively
	augmentatively
	autoschediastically
	biannually
	carefully
	centrally
	challengingly
	collaboratively
	confidentially
	conveniently
	competently
	completely
	continuously
	continually
	dramatically
	dynamically
	enthusiastically
	evangelistically 
	efficiently
	elementarily
	economically
	enormously 
	greatly
	globally
	heterogeneously
	interactively
	paradigmatically
        preemptively
	proactively
	professionally
	quickly
	revolutionarily
	seamlessly
	simultaneously
	synergistically
	vitalistically
	widespreadedly 
     )];
    my $adjectives = [ qw(
	24/365
	24/7
	advanced
	attention-grabbing
	B2B
	B2C
	back-end
	best-of-breed
	bleeding-edge
	bricks-and-clicks
	clicks-and-mortar
	collaborative
	compelling
	corporate
	cross-platform
	cross-media
	customized
	cutting-edge
	distributed
	dot-com
	dynamic
	efficient
	eye-catching
	eigth-generation
	error-free
	edge-of-your-seat
	end-to-end
	enterprise
	enterprise-class
	eligible
	exceptional
	extensible
	essential
	fourth-generation
	fifth-generation
	fine-grained
	frictionless
	front-end
	global
	granular
	guinine
	holistic
	high-yield
	high-end
	impactful
	innovative
	integrated
	interactive
	interdependent
	intuitive
	internet
	industry-wide
	killer
	leading-edge
	low-risk
	magnetic
	market-driven
	mission-critical
	next-generation
	network
	one-to-one
	open-source
	out-of-the-box
	plug-and-play
	performance-oriented
	principle-centered
	proactive
	professional
	prospective
	real-time
	revolutionary
	robust
	scalable
	seamless
	six-generation
	second-generation
	sexy
	slick
	sticky
	strategic
	synergistic
	third-generation
	transparent
	total
	turn-key
	ubiquitous
	unique
	user-centric
	value-added
	vertical
	viral
	virtual
	visionary
	web-enabled
	wireless
	world-class
     ) ];
    my $nouns = [ qw/
	action-items
	applications
	appliances
	architectures
	bandwidth
	channels
	communities
	content
	convergence
	customers
	data
	deliverables
	developments
	e-business
	e-commerce
	e-markets
	e-services
	e-tailers
	environments
	experiences
	eyeballs
	features
	functionalities
	infomediaries
	information
	infrastructures
	initiatives
	interfaces
	markets
	m-commerce
	CEOs
	IPOs
	clusters
	designs
	market-growth
	materials
	methodologies
	metrics
	meta-services
	mindshares
	models
	networks
	niches
	paradigms
	partnerships
	patterns
	platforms
	products
	portals
	relationships
	ROI
	synergies
	segments
	schemas
	services
	solutions
	supply-chains
	systems
	technologies
	users
	web-readiness
        design-patterns / ];

  my @cs;
  foreach ($nouns,$verbs,$adjectives,$adverbs)
    {
    $_ = [ sort @$_ ];
    push @cs, Math::String::Charset->new( { sep => ' ', start => $_ } );
#    $cs[-1]->dump(),"\n"; 
    }
  $bollocks = 
    Math::String::Charset::Grouped->new( { 
      # start => [ @$verbs, @$adjectives, @$nouns ], 
      sets => {
       1  => $cs[3],	# adverbs
       2  => $cs[1],	# verbs
       0  => $cs[2], 	# adjectives
       -1 => $cs[0], 	# nouns
      },
      sep => ' ', } );
  die $bollocks->error() if $bollocks->error() ne "";; 
  }

sub _set_charset
  {
  # store reference to charset object, or make one if given array/hash ref
  # first method should be prefered for speed/memory reasons
  my $self = shift;
  my $cs = shift;

  $cs = $bollocks if !defined $cs;		# default Bollocks charset
  $cs = Math::String::Charset->new( $cs ) if ref($cs) =~ /^(ARRAY|HASH)$/;
  die "charset '$cs' is not a reference" unless ref($cs);
  $self->{_set} = $cs;
  return $self;
  }

sub bzero 
  {
  my @a = (@_,$bollocks); shift @a if @_ == 0;
  my $x = Math::String::bzero(@a); bless $x, __PACKAGE__;
  }

sub binf
  {
  my @a = (@_,$bollocks); shift @a if @_ == 0;
  my $x = Math::String::binf(@a); bless $x, __PACKAGE__;
  }

sub bnan
  {
  my @a = (@_,$bollocks); shift @a if @_ == 0;
  my $x = Math::String::bnan(@a); bless $x, __PACKAGE__;
  } 

sub from_number
  {
  my $x = Math::String::from_number(@_,$bollocks); bless $x, __PACKAGE__;
  }

sub rand 
  {
  # generate a random crap with 4 words
  my $self = shift;

  my $length = int(abs(shift || 4));

  my $x = Dev::Bollocks->new();
  my $len = $bollocks->class($length);
  my $rand = Math::BigInt->new(int(rand($len)));
  $len = $bollocks->class($length-1);
  $rand += $len;
  $x += $rand;
  $x;
  }

sub first
  {
  my $x = shift;

  return $x::SUPER->first(@_) if ref($x);	# $x->first();
  $x = shift if $x eq 'Dev::Bollocks';		# Dev::Bollocks->first(3);
  Math::String->first($x,$bollocks);		# Dev::Bollocks::first(3);
  }

sub last
  {
  my $x = shift;

  return $x::SUPER->last(@_) if ref($x);	# $x->first();
  $x = shift if $x eq 'Dev::Bollocks';		# Dev::Bollocks->last(3);
  Math::String->last($x,$bollocks);		# Dev::Bollocks::last(3);
  }

#############################################################################

=head1 NAME

Dev::Bollocks - Arbitrary sized bollocks straight from middle management

=head1 SYNOPSIS

    use Dev::Bollocks;

    print Dev::Bollocks->new(),"\n";	# create first bollox
    print Dev::Bollocks->rand(),"\n";	# create random bollox
    print Dev::Bollocks::rand(3),"\n";	# create random bollox w/ 3 words

    $x = Dev::Bollocks->rand(),"\n";	# create some random bollox
    for ($i = 0; $i ++; $i < 10)
      {
      print "$x\n"; $x++;		# next bollox
      }

=head1 REQUIRES

perl v5.8.1, L<Math::BigInt>, L<Math::String>, L<Math::String::Charset>,
L<Math::String::Charset::Grouped>

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module implements /dev/bollocks, which generates management bullshit
whenever you need it.

Of course, to follow the spirit outlined in
L<http://www.fatsquirrel.org/veghead/software/bollocks/>
this module doesn't simple do a C<head /dev/bollocks>, that would be too easy,
too fast and non-portable. And bullshit is universilly portable.

Thus the module makes a subclass of Math::String and changes the default
charset to a charset that somewhat emulates and extends the original
/dev/bollocks charset.

As a side-effect you can calculate with bollocks strings, or even compare them
to find out which is greater crap than the other:

	use Dev::Bollocks;

	my $x = Dev::Bollocks->rand();
	my $y = Dev::Bollocks->rand();

	print "$x is more crap than $y\n" if ($x > $y);
	print "$y is more crap than $x\n" if ($y > $x);
	print "$x is the same bollox than $y\n" unless ($y != $x);

=head1 EXAMPLES

Run examples/bollocks.pl to get something like:

 We were told to adaptively monetize holistic market-driven systems.
 It is important to appropriately fashion meta-services.
 We can enthusiastically utilize proactive channels.
 We should paradigmatically streamline e-services.
 Your job is to seamlessly architect dynamic out-of-the-box clusters.
 Our job is to interactively harness high-yield 24/7 markets.
 We were told to widespreadedly supply holistic synergies.
 So, let's assertively grow front-end vertical architectures.
 Your job is to completely exploit scalable meta-services.
 All of us plan to evangelistically empower low-risk edge-of-your-seat content.
 So, let's augmentatively build back-end systems.
 And next we simultaneously transform sexy m-commerce.
 All of us plan to continually benchmark world-class methodologies.
 Your job is to enormously disseminate open-source interactive mindshares.
 So, let's simultaneously transform interfaces.
 Our job is to confidentially coordinate intuitive intuitive e-commerce.
 It is important to paradigmatically embrace robust dot-com solutions.
 And next we appropriately innovate strategic customers.
 All of us plan to challengingly target synergies.
 Our job is to conveniently generate collaborative deliverables.
 It is important to evangelistically synergize high-yield robust IPOs.
 We should competently e-enable convergence.
 All of us plan to economically negotiate action-items.
 It is important to competently integrate value-added efficient users.
 We better widespreadedly promote vertical strategic materials.
 And next we centrally harness convergence.
 So, let's dynamically e-enable out-of-the-box 24/365 customers.
 And next we dramatically enhance efficient development.
 We better biannually enable high-yield metrics.

=head1 INTERNAL DETAILS

I spare you the internal details. You don't want to know the internas of
middle management. Trust me. If you still are inclined to know, see 
L<Math::String>. Don't say I didn't warn you.

=head1 USEFULL METHODS

=head2 B<new()>

            $bollocks = Dev::Bollock->new();

Create a new Dev::Bollocks object with the first bollocks ever. Optionally you
can pass another bollocks string and it will see if it is valid middle
management speak. Never was generating crap so easy!

=head2 B<rand()>

            $bollocks = Dev::Bollock->rand($words);

Create a new, random Dev::Bollocks object with $words words. C<$words> defaults
to 4.

=head2 B<first()>

            $bollocks->first($length);
            $bollocks = Dev::Bollocks->first($length);

Generate the first bollocks of a certain length, length beeing here the number
of words.

=head2 B<last()>

            $bollocks->last($length);
            $bollocks = Dev::Bollocks->last($length);

Same as L<first()>, only does the, well, last crap you expect.

=head2 B<as_number()>

            $bollocks->as_number();

Return internal number as normalized BigInt including sign. 

=head2 B<length()>

            $bollocks->length();

Return the number of characters in the resulting string (aka it's length). It
returns the number of words, since a Dev::Bollocks charset contains the crap
words as 'characters'.

=head2 B<charset()>

            $bollocks->charset();

Return a reference to the charset of the Dev::Bollocks object.

=head1 PERFORMANCE

It is rather slow. This is a feature, not a bug.

=head2 Benchmarks

Were not done on purpose. Nobody expects middle, or any other, for what it
matters, management, to be fast or efficient, so we didn't waste our time in
profiling it.

=head1 PLANS

Bring upper and lower management speak to the, er, waiting masses.

=head1 LICENSE

This program is free crap; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CREDITS

=over 2

=item *

The original idea is from 
L<http://www.fatsquirrel.org/veghead/software/bollocks/>.

=item *

I also found some words by searching the web for "Vision" statements
(L<http://www.google.com> is your friend!). 

=item *

Webster's dictionary. Nowhere you can find gems like autoschediastically,
daffydowndilly or histomorphologically.

=item *

And then there is
L<http://www.dilbert.com/comics/dilbert/career/html/mission_vocab.html>.

=item *

From L<http://www.tomshardware.com/cpu/01q4/011105/index.html>:

I<"This time, AMD attempts to entrench its position in the
performance-oriented high-end segment."> - You just can't make that stuff
up.

=item *

L<http://www.utsglobal.com/products.html>:

...provide enterprise-class UNIX operating environments...
...matched the unique scaleable, mission-critical features...

=item *

The journal I<Displays Europe, issue #1> provided lot's of, uh, well, genuine
[mental note to self: add genuine to the list of adjectives] material:

=over 3

=item An VESA ad

I<"...to foster industry innovation and global market growth">

=item Some headline

I<"organic success stimulates industry-wide bandwagon">

=back

Yeah, whatever.

=back

=head1 AUTHOR

If you use this module in one of your projects (haha!), then please email me.
Or maybe better not. Oh, crap, mail me anyway.

(c) Tels http://bloodgate.com 2001 - 2006.

=cut

1;
