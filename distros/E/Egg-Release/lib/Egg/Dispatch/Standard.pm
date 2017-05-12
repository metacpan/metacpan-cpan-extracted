package Egg::Dispatch::Standard;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Standard.pm 342 2008-05-29 16:05:06Z lushe $
#
use strict;
use warnings;
use Tie::RefHash;
use base qw/ Egg::Dispatch /;

our $VERSION= '3.07';

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub mode_param {
		my $class= shift;  return 0 if ref($class);
		my $pname= shift || croak(q{ I want param name. });
		my $uc_class= uc($class);
		*{"$class\::_get_mode"}= sub {
			my $snip= $_[0]->request->param($pname) || return [];
			$snip=~tr/\t\r\n//d; $snip=~s/ +//g;
			$snip ? [ split /[\/\:\-]+/, $snip ]: [];
		  };
		$class;
	}
  };

sub import {
	my($class)= @_;
	no strict 'refs';  ## no critic
	my $p_class= caller(0);
	my($p_name)= $p_class=~m{(.+?)\:+Dispatch$};
	if ( Tie::RefHash->require ) {
		my $refhash= sub {
			my %refhash;
			tie %refhash, 'Tie::RefHash', @_;
			\%refhash;
		  };
		no warnings 'redefine';
		if (($p_name and $p_name eq 'Egg')
		             or $p_class->can('project_name')) {
			*{"${p_name}::refhash"}= $refhash;
		} elsif ($p_class ne __PACKAGE__) {
			*{"${p_name}::refhash"}= $refhash if $p_name;
			*{"${p_class}::refhash"}= $refhash;
		}
	} else {
		warn q{ 'Tie::RefHash' is not installed. };
	}
	$class->SUPER::import;
}
#sub _setup {
#	my($e)= @_;
#	my $default= $e->config->{deispath_default_name} ||= '_default';
#	$e->dispatch_map->{$default}= sub {} unless $e->dispatch_map->{$default};
#	$e->next::method;
#}
sub dispatch {
	$_[0]->{Dispatch} ||= Egg::Dispatch::Standard::handler->new(@_);
}
sub _dispatch_map_check {
	my($self, $hash, $myname)= @_;
	while (my($key, $value)= each %$hash) {
		if (! ref($key) and $key=~/^ARRAY\(0x[0-9a-f]+\)/) {
			warn
			  qq{ Please use the refhash function. '$myname' \n}
			. qq{ The key not recognized as ARRAY is included. };
		}
		if (ref($value) eq 'HASH') {
			my $name= ref($key) eq 'ARRAY' ? do {
				$key->[0] || die qq{It is a setting of '$myname'}
				               . qq{ and there is an action name undefinition.};
			  }: $key;
			$self->_dispatch_map_check($value, $name);
		}
	}
	$hash;
}


package Egg::Dispatch::Standard::handler;
use strict;
use base qw/ Egg::Dispatch::handler /;

__PACKAGE__->mk_accessors(qw/ parts _backup_action /);

sub _initialize {
	my $self= shift->SUPER::_initialize;
	$self->parts( $self->e->_get_mode || [@{$self->e->snip}] );
	$self;
}
sub mode_now {
	my $self = shift;
	my $now  = $self->action;
	my $label= $self->label;
	my $num  = $#{$label}- (shift || 0);
	$num< 0 ? "": (join('/', @{$now}[0..$num]) || "");
}
sub label {
	my $self= shift;
	return $self->{label} unless @_;
	$self->{label}->[$_[0]] || "";
}
sub _start {
	my($self)= @_;
	my $e= $self->e;
	my $begins= [];
	my $ends  = [];
	$self->{__parts_num}= 0;
	$self->_scan_mode(
	   $e, $begins, $ends, $self->parts, 0,
	   $e->_dispatch_map, $self->default_mode,
	   ($self->e->request->is_post || 0),
	   );
	return 0 if $self->e->finished;
	if (exists($self->{__parts_num})) {
		$self->action([ @{$self->parts}[0..$self->{__parts_num}] ]);
		for my $code (@$begins) {
			last if $e->{finished};
			$code->($e, $self);
		}
		if (my $title= $self->{label}[$#{$self->{label}}]) {
			$self->page_title($title);
		};
	} else {
#		$self->action([]);
		$e->finished('404 Not Found');
	}
	$self->{_end_code}= $ends;
	1;
}
sub _action {
	my($self)= @_;
	return 0 if $self->e->{finished};
	my $action= tied($self->parts->[$self->{__parts_num}]);
	$action->[1]->($self->e, $self, $action->[2]);
	1;
}
sub _finish {
	my($self)= @_;
	$_->($self->e, $self) for @{$self->{_end_code}};
	1;
}
sub _scan_mode {
	my($self, $e, $begins, $ends, $parts, $num, $map, $default, $is_post)= @_;
	$self->{_action_now}= $num;
	my $wanted= $parts->[$num] ||= "";
	   $wanted=~s{\.[^\.]{1,4}$} [];
	my $default_code;
	for my $key (keys %$map) {
		my $value= $map->{$key} || next;;
		my $page_title= "";
		my $point= ref($key) eq 'ARRAY' ? do {
			if ($key->[1]) {
				if ($is_post) {
					if ($key->[1]< 2) {
						$self->e->finished('405 Method Not Allowed.');
						return 0;
					}
				} else {
					if ($key->[1]> 1) {
						$self->e->finished('405 Method Not Allowed.');
						return 0;
					}
				}
			}
			$page_title= $key->[2] || "";
			$key->[0] || next;
		  }: $key;
		if (my @piece= $wanted=~m{^$point$}) {
			next if $point=~/^_/;
			$page_title ||= $wanted;
			push @{$self->{label}}, $page_title;
			if ($map->{_begin}) { push @$begins, $map->{_begin} }
			if ($map->{_end})   { unshift @$ends, $map->{_end}  }
			if (@piece) {
				tie $parts->[$num],
				    'Egg::Dispatch::Standard::TieScalar',
				    $wanted, $value, \@piece;
			} else {
				$parts->[$num]= $wanted;
			}
			if (ref($value) eq 'HASH') {
				return $self->_scan_mode($e, $begins, $ends, $parts,
				      ($num+ 1), $value, $default, $is_post) ? 1: 0;
			} else {
				$self->page_title($page_title);
				$self->{__parts_num}= $num;
				return 1;
			}
		} elsif ($point eq $default) {
			$default_code= [$value, $page_title];
		}
	}
	return 0 if $self->e->finished;
	if (! $self->{__parts_num} and $default_code) {
		if ($map->{_begin}) { push @$begins, $map->{_begin} }
		if ($map->{_end})   { unshift @$ends, $map->{_end}  }
		push @{$self->{label}}, ($default_code->[1] || $self->default_name);
		tie $parts->[$num], 'Egg::Dispatch::Standard::TieScalar',
		    $self->default_name, $default_code->[0], [];
		$self->{__parts_num}= $num;
		return 1;
	}
	0;
}
sub _example_code {
	my($self)= @_;
	my $a= { project_name=> $self->e->namespace };

	<<END_OF_EXAMPLE;
#
# Example of controller and dispatch.
#
package $a->{project_name}::Dispatch;
use strict;
use warnings;

$a->{project_name}-&gt;dispatch_map( refhash (
  
  # 'ANY' matches to the method of requesting all.
  # The value of label is used with page_title.
  { ANY => '_default', label => 'index page.' }=> sub {
    my(\$e, \$dispatch)= \@_;
    \$e->template('document/default.tt');
    },
  
  # Empty CODE decides the template from the mode name that becomes a hit.
  # In this case, it is 'Help.tt'.
  help => sub { },
  
  # When the request method is only GET, 'GET' is matched.
  { GET => 'bbs_view', label => 'BBS' } => sub {
    my(\$e, \$dispatch)= \@_;
    .... bbs view code.
    },
  
  # When the request method is only POST, 'POST' is matched.
  { POST => 'bbs_post', label => 'BBS Contribution.' } => sub {
    my(\$e, \$dispatch)= \@_;
    .... bbs post code.
    },
  
  # 'A' is an alias of 'ANY'.
  { A => 'blog', label => 'My BLOG' }=>
  
    # The refhash function for remembrance' sake when you use HASH for the key.
    refhash (
  
    # Prior processing can be defined.
    _begin => sub {
      my(\$e, \$dispatch)= \@_;
      ... blog begin code.
      },
  
    # 'G' is an alias of 'GET'.
    # The regular expression can be used for the action. A rear reference is
    # the third argument that extends to CODE.
    { G => qr{^article_(&yen;d{4}/&yen;d{2}/&yen;d{2})}, label => 'Article' } => sub {
      my(\$dispatch, \$e, \$parts)= \@_;
      ... data search ( \$parts->[0] ).
      },
  
    # 'P' is an alias of 'POST'.
    { 'P' => 'edit', label => 'BLOG Edit Form.' } => sub {
      my(\$e, \$dispatch)= \@_;
      ... edit code.
      },
  
    # Processing can be defined after the fact.
    _end => sub {
      my(\$e, \$dispatch)= \@_;
      ... blog begin code.
      },
  
    ),

  ) );

1;
END_OF_EXAMPLE
}


package Egg::Dispatch::Standard::TieScalar;
use strict;

sub TIESCALAR {
	my($class, $orign)= splice @_, 0, 2;
	bless [$orign, @_], $class;
}
sub FETCH { $_[0][0] }
sub STORE { $_[0][0]= $_[1] }

1;

__END__

=head1 NAME

Egg::Dispatch::Standard - Dispatch of Egg standard.

=head1 SYNOPSIS

  package MyApp::Dispatch;
  use base qw/ Egg::Dispatch::Standard /;
    
  # If the attribute is applied to the key, it sets it with ARRAY by using the 
  # refhash function.
  Egg->dispatch_map( refhash(
  
  # The content of ARRAY of the key from the left. 'Action name', 'Permission 
  # -method', 'Title name'
  # * When 0 is set, the permission method passes everything.
  [qw/ _default 0 /, 'index page.']=> sub {
    my($e, $dispatch)= @_;
    $e->template('document/default.tt');
    },
  
  # The second element of key ARRAY is set to one when permitting only at 'GET'
  # request.
  [qw/ bbs_view 1 /, 'BBS']=> sub {
    my($e, $dispatch)= @_;
    .... bbs view code.
    },
  
  # The second element of key ARRAY is set to two when permitting only at 'POST'
  # request.
  [qw/ bbs_post 2 /, 'Contribution.']=> sub {
    .... bbs post code.
    },
  
  # Empty CODE decides the template from the list of the action name that becomes
  # a hit. In this case, it is 'help.tt'.
  help => sub { },
  
  [qw/ blog 0 /, 'My BLOG']=>
  
    # The refhash function for remembrance' sake when you use ARRAY for the key.
    refhash(
  
    # Prior processing can be defined by '_begin'.
    _begin => sub {
      my($e, $dispatch)= @_;
      ... blog begin code.
      },
  
    # The regular expression can be used for the action. A rear reference is the
    # third argument over CODE.
    [qr{^article_(\d{4}/\d{2}/\d{2})}, 0, 'Article']=> sub {
      my($e, $dispatch, $parts)= @_;
      ... data search ( $parts->[0] ).
      },
  
    # A rear reference for a shallower hierarchy extracts the value of
    # $e->dispatch->parts with 'tied'.
    qr{^[A-Z]([a-z0-9]+)}=> {
      qr{^User([A-Z][a-z0-9_]+)}=> {
      my($e, $dispatch, $match)= @_;
      my $low_match= tied($dispatch->parts->[0])->[2];
      ... other code.
      },
  
    [qw/ edit 0 /, 'BLOG Edit Form.']=> sub {
      my($e, $dispatch)= @_;
      ... edit code.
      },
  
    # Processing can be defined by '_end' after the fact.
    _end => sub {
      my($e, $dispatch)= @_;
      ... blog begin code.
      },
  
    # Time when 11 dispatch is set can be saved if it combines with $e->snip2template.
    # Refer to L<Egg::Util> for 'snip2template' method.
    help => {
      _default=> sub {},
      qr{^[a-z][a-z0-9_]+}=> sub {
        my($e, $dispatch)= @_;
        $e->snip2template(1) || return $e->finished('404 Not Found.');
        },
      },
  
    ),
  
    ) );

=head1 DESCRIPTION

It is dispatch of the Egg standard.

Dispatch is processed according to the content defined in 'dispatch_map'.

Dipatti of the layered structure is treatable.

The value of the point where the action the final reaches should be CODE 
reference.

Objec of the project and the handler object of dispatch are passed for the CODE
reference.

It corresponds to the key to the ARRAY form by using the refhash function.
see L<Tie::RefHash>.

Page title corresponding to the matched place is set, and the request method 
can be limited and it match it by using the key to the ARRAY form.

The regular expression can be used for the key. As a result, it is possible to 
correspond to a flexible request pattern.
Moreover, because a rear reference can be received, it is treatable in the CODE 
reference.

  # 1.
  qr{^baz_(.+)}=> { 
     # 2.
     qr{^boo_(.+)}=> sub {
        my($d, $e, $p)= @_;
        },
    },

As for such dispatch, the rear reference obtained by '# 2' is passed to the third
argument of the CODE reference.
In a word, the value of $p is a rear reference corresponding to the regular 
expression of '# 2' and the content is ARRAY reference.

To process the rear reference obtained in the place of '# 1', tied is used and 
extracted from the value of $e-E<gt>action.

  # Because the key to '# 1' is a regular expression that picks up a rear reference,
  # piece zero element of $e->dispatch->parts is set with Tie SCALAR.
  # When the value is done in tied, and the ARRAY object is acquired, the second
  # element is a value of a rear reference.
  my $p1_array= tied($e->dispatch->parts->[0])->[2];
  
  # And, the element number of a rear reference wanting it is specified.
  my $match= $p1_array->[0];
  
  # By the way, '# 2' can be similarly acquired from the first element.
  #  my $p2_array= tied($e->dispatch->parts->[1])->[2];

'_begin' is executed from the one of a shallower hierarchy. When $e->finished is
set on the way, '_begin' of a hierarchy that is deeper than it is not processed.

It processes it after the fact when '_end' key is defined.
Even if it is executed from the one of the hierarchy with deeper matched action,
and $e-E<gt>finished is set on the way, '_end' processes '_end' of a shallower
hierarchy. Therefore, it is necessary to check $e-E<gt>finished on the code side.

=over 4

=item * mode_param, dispatch_map

=back

=head1 WARNING

Some specifications have changed because of Egg::Response-3.12.

The change part is as follows.

=over 4

=item * When a rear reference was obtained, the content of the action of the correspondence element was preserved with Tie Scalar.

As a result, acquiring a rear reference for a shallower hierarchy became 
possible.

=item * It was made to do with ARRAY when the attribute was set to the key to dispatch.

Because the referred attribute is few, it is not troublesomely seen to set it 
with HASH easily.

=item * The order of evaluating '_begin' reversed.

Processing it from a deeper hierarchy before to a shallow hierarchy is still 
strange.

=back

=head1 EXPORT FUNCTION

It is a function exported to the controller and the dispatch class of the project.

=head2 refhash ([HASH])

Received HASH is returned and after Tie is done with L<Tie::RefHash>, the content is 
returned by the HASH reference.

When the key to the ARRAY form is set to 'dispatch_map', it is indispensable.

It doesn't go well even if the reference is passed to this function.
Please pass it by a usual HASH form.

  # This is not good.
  my $hashref = refhash ({
     [qw/ _default 0 /, 'index page.']=> sub {},
     [qw/ help     0 /, 'help page.' ]=> sub {},
     });

  # It is OK.
  my $hashref = refhash (
     [qw/ _default 0 /, 'index page.']=> sub {},
     [qw/ help     0 /, 'help page.' ]=> sub {},
     );

=head1 METHODS

L<Egg::Dispatch> has been succeeded to.

=head2 dispatch

The 'Egg::Dispatch::Standard::handler' object is returned.

  my $d= $e->dispatch;

=head1 HANDLER METHODS

=head2 mode_now

The value in which the list of the matched action ties by '/' delimitation is 
returned.

=head2 label ( [NUMBER] )

The list of the matched action is returned by the ARRAY reference.

When the figure is given, the corresponding value is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Dispatch>, 
L<Tie::RefHash>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

