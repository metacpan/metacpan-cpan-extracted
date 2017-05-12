package Egg::Plugin::Filter;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Filter.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use HTML::Entities;
use Carp qw/croak/;

our $VERSION= '3.01';

my $EGG= 0;
my $VAL= 1;
my $ARG= 2;

our %Filters= (
 trim=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~s{^\s+} []s;
   ${$_[$VAL]}=~s{\s+$} []s;
   },
 hold=> sub {
   ${$_[$VAL]}=~s{\s+} []sg if defined(${$_[$VAL]});
   },
 hold_crlf=> sub {
   ${$_[$VAL]}=~tr/\n//d  if defined(${$_[$VAL]});
   },
 hold_tab=> sub {
   ${$_[$VAL]}=~tr/\t//d if defined(${$_[$VAL]});
   },
 hold_blank=> sub {
   ${$_[$VAL]}=~s{ +} []sg if defined(${$_[$VAL]});
   },
 hold_html=> sub {
   ${$_[$VAL]}=~s{<.+?>} []sg  if defined(${$_[$VAL]});
   },
 strip=> sub {
   ${$_[$VAL]}=~s{\s+} [ ]sg if defined(${$_[$VAL]});
   },
 strip_blank=> sub {
   ${$_[$VAL]}=~s{ +} [ ]sg if defined(${$_[$VAL]});
   },
 strip_tab=> sub {
   ${$_[$VAL]}=~s{\t+} [ ]sg if defined(${$_[$VAL]});
   },
 strip_html=> sub {
   ${$_[$VAL]}=~s{<.+?>} [ ]sg if defined(${$_[$VAL]});
   },
 strip_crlf=> sub {
   ${$_[$VAL]}=~s{\n+} [ ]sg if defined(${$_[$VAL]});
   },
 crlf=> sub {
   return 0 unless defined(${$_[$VAL]});
   my $re= "\n" x
      ( $_[$ARG]->[0] ? (($_[$ARG]->[0]=~/(\d+)/)[0] || 2 ): 2 );
   ${$_[$VAL]}=~s{\n\n+} [$re]sge;
   },
 escape_html=> sub {
   ${$_[$VAL]}= &__escape_html(${$_[$VAL]}) if defined(${$_[$VAL]});
   },
 digit=> sub {
   ${$_[$VAL]}=~s{\D} []g if defined(${$_[$VAL]});
   },
 alphanum=> sub {
   ${$_[$VAL]}=~s{\W} []g if defined(${$_[$VAL]});
   },
 integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^([\-\+]?\d+)/ ? $1: undef;
   },
 pos_integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9+//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^(\+?\d+)/ ? $1: undef;
   },
 neg_integer=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/0-9-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^(\-?\d+)/ ? $1: undef;
   },
 decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^([\-\+]?\d+\.?\d*)/ ? $1: undef;
   },
 pos_decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^(\+?\d+\.?\d*)/ ? $1: undef;
   },
 neg_decimal=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/^(\-?\d+\.?\d*)/ ? $1: undef;
   },
 dollars=> sub {
   return 0 unless defined(${$_[$VAL]});
   ${$_[$VAL]}=~tr/,/./; ${$_[$VAL]}=~tr/0-9.+-//dc;
   ${$_[$VAL]}= ${$_[$VAL]}=~/(\d+\.?\d?\d?)/ ? $1: undef;
   },
 phone=> sub {
   ${$_[$VAL]}=~s/[^\d,\(\)\.\s,\-#]//g if defined(${$_[$VAL]});
   },
 sql_wildcard=> sub {
   ${$_[$VAL]}=~tr/*/%/ if defined(${$_[$VAL]});
   },
 quotemeta=> sub {
   ${$_[$VAL]}= quotemeta(${$_[$VAL]}) if defined(${$_[$VAL]});
   },
 uc=> sub {
   ${$_[$VAL]}= uc(${$_[$VAL]}) || "";
   },
 ucfirst=> sub {
   ${$_[$VAL]}= ucfirst(${$_[$VAL]}) || "";
   },
 lc=> sub {
   ${$_[$VAL]}= lc(${$_[$VAL]}) || "";
   },
 lc_email=> sub {
   return 0 unless ${$_[$VAL]};
   ${$_[$VAL]}=~s{\s+} []sg;
   ${$_[$VAL]}=~s{(.+?\@)([^\@]+)$} [$1. lc($2)]e;
   },
 uri=> sub {
   return 0 unless ${$_[$VAL]};
   require URI;
   ${$_[$VAL]}=~s{\s+} []sg;
   my $uri= URI->new(${$_[$VAL]});
   ${$_[$VAL]}= $uri->canonical;
   },
 regex=> sub {
   return 0 unless defined(${$_[$VAL]});
   for (@{$_[$ARG]}) { ${$_[$VAL]}=~s{$_} []sg }
   },
 );

$Filters{hold_space}  = $Filters{hold_blank};
$Filters{strip_space} = $Filters{strip_blank};
$Filters{url}         = $Filters{uri};
$Filters{email}       = $Filters{lc_email};
$Filters{int}         = $Filters{integer};

sub _filters { \%Filters }

sub _setup {
	my($e)= @_;
	my $config= $e->config->{plugin_filter} ||= {};
	if ($config->{plugins}) {
		for my $name (ref($config->{plugins}) eq 'ARRAY'
		                ? @{$config->{plugins}}: $config->{plugins}) {
			my $pkg= $name=~m{^\++(.+)} ? $1
			       : __PACKAGE__. "::Plugin::$name";
			$pkg->require or die __PACKAGE__.": Error: $@";
			if (my $code= $pkg->can('_filters')) {
				my $hash= $code->($pkg, $e) || next;
				@Filters{keys %$hash}= values %$hash;
			} elsif (my $setup= $pkg->can('_setup_filters')) {
				$setup->($pkg, $e);
			}
		}
	}
	unless ($e->isa('Egg::Plugin::Encode')) {
		my $class= $e->global->{request_class};
		my $code = $class->can('parameters') || \&Egg::Request::parameters;
		no strict 'refs';  ## no critic.
		no warnings 'redefine';
		*{"${class}::parameters"}= sub {
			$_[0]->{parameters} ||= do {
				my $pm= $code->(@_) || {};
				while (my($key, $v)) {
					next unless defined($v);
					if (ref($v) eq 'ARRAY') {
						for (@$v) { tr/\r//d }
						$pm->{$key}= $v;
					} else {
						$pm->{$key}=~tr/\r//d;
					}
				}
				$pm;
			  };
		  };
	}
	$e->next::method;
}
sub filter {
	my $e= shift; $_[0] || die q{ I want filter attr. };
	my($args, $pm)= ref($_[0]) eq 'HASH'
	    ? (shift, (shift || $e->request->params))
	    : ({@_}, $e->request->params);
	MAINFILTER:
	while (my($key, $config)= each %$args) {
		if ($key=~m{\[}) {
			my($a, @item)= __parse($key);
			exists($pm->{$a}) and croak qq{ '$a' already exists. }; 
			$pm->{$a}= join '', map{defined($_) ? $_: ""}@{$pm}{@item};
			$key= $a;
		}
		next unless $pm->{$key};
		QUERYPARAM:
		for (ref($pm->{$key}) eq 'ARRAY' ? @{$pm->{$key}}: $pm->{$key}) {
			my $value= \$_;
			FILTERPIECE:
			for my $piece (@$config) {
				my($name, @args)= $piece=~m{\[} ? __parse($piece): ($piece, ());
				my $func= $Filters{$name} || die qq{ '$name' filter is empty. };
				eval { $func->($e, $value, \@args) };
				$@ and die __PACKAGE__. ": $@";
			}
		}
	}
	$pm;
}
sub __parse {
	$_[0]=~m{^([^\[]+)\[(.+)} || croak qq{ filter error - '$_[0]' };
	my($n, $p)= ($1, $2);
	$p=~s{\]\s*$} [];
	my @tmp;
	eval "\@tmp = ($p)"; $@ and croak $@;  ## no critic.
	($n, @tmp);
}
sub __escape_html { &HTML::Entities::encode_entities(shift, q{'"&<>}) }

1;

__END__

=head1 NAME

Egg::Plugin::Filter - Plugin to regularize input data.

=head1 SYNOPSIS

  use Egg qw/ Filter /;
  
  # The received form data is filtered.
  $e->filter(
   myname => [qw/ hold_html abs_strip trim /],
   address=> [qw/ hold_html crlf:2 abs_strip trim /],
   tel    => [qw/ hold phone /],
   );

  # Cookie is filtered.
  my $cookie= $e->filter( {
    nick_name=> [qw/ strip_html abs_strip trim /],
    email    => [qw/ hold_html hold /],
    }, $e->request->cookies );

=head1 DESCRIPTION

It is a plugin target to remove the problem part from data input to the form.

An original filter can be defined in %Filters.

  package MyApp;
  use Egg qw/ Filter /;
  
  {
     my $filter= \%Egg::Plugin::Filter::Filters;
  
     $filter->{myfilter}= sub {
          my($e, $value, $arg)= @_;
          ..........
          ...
       };
  };

Those filters cannot be used when overwriting because the filter of default is
defined in %Filters beforehand.

The name of the defined key becomes the name of the filter.

The object of the project and the value of the object parameter are passed for
the set CODE reference.  Moreover, when it is being made to have in the argument
by the filter, it is passed by the third element.

There is especially no return value needing.

=head1 METHODS

=head2 filter ( [ATTR_HASH], [PARAM_HASH] )

The filter is processed.

ATTR_HASH is a filter setting, and the key is a name of the processed parameter.
The value enumerates the name of the filter with ARRAY.

  $e->filter(
    param_name1 => [qw/ strip space trim /],
    param_name2 => [qw/ strip_html space trim /],
    param_name3 => [qw/ strip_html crlf:3 trim /],
    );

The thing that connects the values of the parameter and processes it can be 
done.

  $e->filter(
    'anyparam[qw/ param_name1 param_name2 /]' => [qw/ strip space trim /],
    );

It is processed being made 'anyparam' to connect 'param_name1' and 'param_name2'
by this.

When the argument can be given to the filter, the argument can be passed according
to points like the connection of parameters.

  $e->filter(
    param1 => ["regex['^\s+', '\s+$]"],
    );

The processed parameter is passed to PARAM_HASH.
When this is unspecification, $e-E<gt>request-E<gt>params is used.

=head1 FILTERS

=head2 trim

The space character in the back and forth is deleted.

=head2 hold

The space character is completely deleted.

=head2 hold_crlf

It is 'hold' in the object only as for changing line and the tab.

=head2 hold_tab

The tab is deleted.

=head2 hold_blank

Consecutive half angle space is settled in one.

Alias is 'hold_space'.

=head2 hold_html

The character string seen the HTML tag is deleted.

=head2 strip

The continuousness of the space character is substituted for one half angle
space.

=head2 strip_blank

The continuousness of half angle space is substituted for one half angle space.

Alias is 'strip_space'.

=head2 strip_tab

Continuousness in the tab is substituted for one half angle space.

=head2 strip_html

The character string seen the HTML tag is substituted for one half angle space.

=head2 strip_crlf

It is 'strip' for changing line and the tab.

=head2 crlf [NUM]

A consecutive changing line is settled in NUM piece.  The tab is deleted.

Default when NUM is omitted is 2.

  param1 => [qw/ crlf[3] /]

=head2 escape_html

It is 'encode_entities' of L<HTML::Entities>.

=head2 digit

It deletes it excluding the normal-width figure.

=head2 alphanum

It deletes it excluding the alphanumeric character.

=head2 integer

It deletes it excluding the integer.

=head2 pos_integer

It deletes it excluding the positive integer.

=head2 neg_integer

It deletes it excluding the negative integer.

=head2 decimal

It deletes it excluding the integer including small number of people.

=head2 pos_decimal

It deletes it excluding a positive integer including small number of people.

=head2 neg_decimal

It deletes it excluding a negative integer including small number of people.

=head2 dollars

It deletes it excluding the figure that can be used with dollar currency.

=head2 phone

The character that cannot be used by the telephone number is deleted.

=head2 sql_wildcard

'*' is substituted for '%'.

=head2 quotemeta

Quotemeta is done.

=head2 uc

uc is done.

=head2 ucfirst

ucfirst is done.

=head2 lc

lc is done.

=head2 lc_email

The domain name part in the mail address is converted into the small letter.

  MyName@DOMAIN.COM => MyName@domain.com

Alias is 'email'.

=head2 uri

The domain name part of URL is converted into the small letter.

  http://MYDOMAIN.COM/Hoge/Boo.html => http://mydomain.com/Hoge/Boo.html

Alias is 'url'.

=head2 regex ([REGEXP])

The part that matches to the regular expression specified for REGEXP is deleted.
REGEXP is two or more contact.

  param1 => ["regex['abc', 'xyz']"],

=head1 SEE ALSO

L<Egg::Release>,
L<HTML::Entities>,
L<URI>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

