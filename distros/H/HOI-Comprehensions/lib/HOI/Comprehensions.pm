package HOI::Comprehensions;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( comp );
our $VERSION = '0.045';


sub comp {
    my $computation = shift;
    my $generators_ = \@_;
    sub {
        my @guards = @_;
        my %generators;
        my ($evalstr, $postfix) = ("", "");
        my $self_;
        while ($#$generators_ > -1) {
            my ($key, $value) = (shift @$generators_, shift @$generators_);
            $evalstr .= '$self->{generators}->{'.$key.'}->(';
            $postfix .= ')';
            $generators{$key} = 
                (ref($value) eq 'ARRAY') ? 
                    sub { 
                        my $idx = 0; 
                        sub { 
                            if ($#_ == -1) {
                                my $last_ret = (defined $value->[$idx]) ? { $key => $value->[$idx] } : {};
                                $idx++;
                                my $last_done = ($idx > $#$value);
                                $idx %= ($#$value + 1) if ($#$value > -1);
                                return ($last_done, $last_ret);
                            }
                            my ($done, $res) = @_;
                            my $ret = { %$res, $key => $value->[$idx] };
                            $idx++ if ($done);
                            my $self_done = ($idx > $#$value);
                            $idx %= ($#$value + 1);
                            ($self_done, $ret);
                        } 
                    }->() : 
                    ( (ref($value) eq 'HOI::Comprehensions') ? 
                        sub { 
                            my $value_ = $value;
                            my $idx = 0;
                            sub {
                                my $forward = 
                                sub {
                                    my ($ret, $forward_done);
                                    if ($value_->{all_done}) {
                                        ($ret) = $value_->{list}->[$idx];
                                        $idx++;
                                        $forward_done = ($idx > $#{$value_->{list}});
                                        $idx %= ($#{$value_->{list}} + 1);
                                        return ($forward_done, $ret);
                                    }
                                    ($ret, $forward_done) = $value_->next(0);
                                    ($forward_done, $ret)
                                };
                                if ($#_ == -1) {
                                    my ($last_done, $last_res) = $forward->();
                                    return ($last_done, { $key => $last_res });
                                }
                                my ($done, $res) = @_;
                                my ($self_done, $self_res) = $forward->();
                                my $ret = { %$res, $key => $self_res };
                                ($self_done * $done, $ret);
                            }
                        }->() :
                        sub { 
                            if ($#_ == -1) {
                                my ($last_res, $last_done) = $value->();
                                $last_done = 1 if (not defined $last_done);
                                return ($last_done, { $key => $last_res });
                            }
                            my ($done, $res) = @_;
                            my ($self_res, $self_done) =
                            sub {
                                my $scopestr = '';
                                my ($package_name) = $self_->{caller};
                                local $AttrPrefix = $package_name.'::';
                                for my $elt (keys %$res) {
                                    $scopestr = 'local $'."$AttrPrefix"."$elt"." = \$res->{$elt}; ";
                                }
                                eval $scopestr.'$value->()';
                                #$value->();
                            }->();
                            $self_done = 1 if (not defined $self_done);
                            my $ret = { %$res, $key => $self_res };
                            ($self_done * $done, $ret);
                        }
                    );
        }
        $self_ =
        bless
        { 
            computation => $computation, 
            generators => \%generators, 
            all_done => 0,
            geneitr => $evalstr.$postfix,
            guards => \@guards, 
            list => [],
            caller => caller()
        }
    }
}

sub get_member {
    my ($self, $name) = @_;
    $self->{$name}
}

sub get_list {
    my ($self) = @_;
    $self->get_member('list')
}

sub is_over {
    my ($self) = @_;
    $self->get_member('all_done')
}

sub step_next_lazy {
    my ($self, $flag) = @_;
    return ($self->{list}, 1) if ($self->{all_done});
    my ($done, $arguments) = eval $self->{geneitr};
    $self->{all_done} = $done;
    my ($package_name) = $self->{caller};
    local $AttrPrefix = $package_name.'::';
    my $evalstr = '';
    for my $key (keys %$arguments) {
        $evalstr .= 'local $'."$AttrPrefix"."$key".' = $arguments->{'."$key".'}; ';
    }
    my %switches = (
        full => sub { 
            my $guards_ok = 1; 
            eval '{'.$evalstr.'($_->($arguments) or $guards_ok = 0) for (@{$self->{guards}}); '.'push @{$self->{list}}, $self->{computation}->($arguments) if ($guards_ok); '.'}';
            $guards_ok 
        },
    );
    my $guard = 0;
    $guard = $switches{$flag}->() if (scalar(keys %$arguments) == scalar(keys %{$self->{generators}}));
    ($self->{list}, $done, $guard)
}

sub next { 
    my ($l_, $done, $guard);
    for my $cnt (0..$_[1]) {
        do {
            ($l_, $done, $guard) = $_[0]->step_next_lazy('full'); 
        } until ($done or $guard);
    }
    ($l_->[$#$l_], $done, $guard)
}

sub next { 
    my ($l_, $done, $guard);
    #print "cnt to $_[1]\n";
    for my $cnt (0..$_[1]) {
        do {
            ($l_, $done, $guard) = $_[0]->step_next_lazy('full'); 
        } until ($done or $guard);
    }
    ($l_->[$#$l_], $done, $guard)
}

use overload
    '<>' => sub { my @ret = $_[0]->next(0); \@ret },
    '+' => 
    sub { 
        #print(scalar(@{$_[0]->{list}}), ' ', $_[1], "\n"); 
        my @ret = (scalar(@{$_[0]->{list}}) - 1 >= $_[1]) ? ($_[0]->{list}->[$_[1]], $_[0]->{all_done}) : ($_[0]->next($_[1] - scalar(@{$_[0]->{list}}))); 
        \@ret 
    },
    ;

1;

sub force {
    my $self = shift;
    if (not $self->{all_done}) {
        my ($elt, $done);
        do {
            ($elt, $done) = @{<$self>};
        } while (not $done);
    }
    $self->{list}
}

__END__

=head1 NAME

HOI::Comprehensions - Higher-Order Imperative "Re"features in Perl: List Comprehensions

=head1 SYNOPSIS

  use HOI::Comprehensions;

  my $list = HOI::Comprehensions::comp( sub { $x + $y + $z + $w }, x => [ 1, 2, 3 ], y => [ 4, 5, 6 ], w => HOI::Comprehensions::comp( sub { $u }, u => [ 1, 2, 3 ] )->(), z => sub { (2, 1) } )->( sub { $x > 1 } );

  my ($elt, $done);
  do {
      ($elt, $done) = @{<$list>};
      print "$elt ";
  } while (not $done);
  print "\n";

=head1 DESCRIPTION

HOI::Comprehensions offers lazy-evaluated list comprehensions with limited support to 
generators of an infinite list. It works as if evaluating multi-level loops lazily.

Currently, the generators are handled in sequence of the argument list offered by the user.
As a result of such implementation, a list
    { (x, y) | x belongs to { 0, 1 }, y belongs to natural number set }
may be trapped in the inner infinite loop. To avoid such situation, make sure finite generators 
are subsequent to all the infinite ones.

=head1 FUNCTIONS

=head2 comp($@)->(@)

For creating a list comprehension object. The formula for computing the elements of
the list is given as a subroutine, following by the generators, in form of name => arrayref, 
name => subroutine or name => comprehension. Comp returns a function which takes all guards 
in form of subroutines. Guard parameters can be left empty if there is no guard.

The variable names for naming the ganerators could be used directly in the computation sub and
all guard subs without strict vars enabled. They have local scope as if they were declared with
keyword 'local' in Perl.

A hashref which holds generator variables as its keys and value of those variables as
its values is passed to the formula subroutine. However, it is recommended to use such
variables directly instead of dereference the hashref.

Generators can be arrayrefs, subroutines or list comprehensions. A subroutine generator should 
return a pair ( elt, done ), where elt is the next element and done is a flag telling whether
the iteration is over, or return a single element.

It is possible that some generator A is dependent on another generator B. In that case, B
must be subsequent to A. See test cases for details.

The subroutine comp is in EXPORT_OK, but it is not exported by default.

=head1 METHODS

=head2 get_list

Get the list member of a list comprehension object. It returns a arrayref which holds
the actual list evaluated so far.

=head2 is_over

Returns a boolean which tells if the evaluation of the list is over.

=head2 get_member($)

Get a member of a list comprehension object by name.
A list comprehension object is actually a blessed hashref.

=head2 force

Eval the comprehension eagerly. Beware - it will be trapped forever in an infinite 
comprehension.
The method returns the evaluated list reference.

=head1 OPERATORS

=head2 <>

List evaluation iterator. Returns the "next" element generated in the sequence in the 
situation of eager evaluation, and a flag telling whether the evaluation is done, together
in a arrayref.

=head2 +

List indexing operator. Takes an integer as the index and a list comprehension object.
The operator returns an arrayref [ $elt, $done ], where $elt is the element at the given
index and $done is a flag telling whether the evaluation is done.

=head1 AUTHOR

withering <withering@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by withering

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
