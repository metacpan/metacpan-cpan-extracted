package Dezi::ReplaceRules;
use Moose;
with 'Dezi::Role';
use Scalar::Util qw( blessed );
use Carp;
use Data::Dump qw( dump );
use Text::ParseWords;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = '0.015';

has 'rules' => ( is => 'rw', isa => 'ArrayRef' );

=pod

=head1 NAME

Dezi::ReplaceRules - filename mangler

=head1 SYNOPSIS

 use Dezi::ReplaceRules;
 my $rules = Dezi::ReplaceRules->new(
   qq(replace "the string you want replaced" "what to change it to"),
   qq(remove  "a string to remove"),
   qq(prepend "a string to add before the result"),
   qq(append  "a string to add after the result"),
   qq(regex   "/search string/replace string/options"),
 );
 my $uri = 'foo/bar/baz';
 my $modified_uri = $rules->apply($uri);

=head1 DESCRIPTION

Dezi::ReplaceRules is a pure Perl replacement for the ReplaceRules
configuration feature in Swish-e.

This class is typically used internally by Dezi. The filter()
feature of Dezi is generated to use ReplaceRules if they are defined
in a Dezi::Indexer::Config object or config file.

=head1 METHODS

=head2 new( I<rules> )

Constructor for new ReplaceRules object. I<rules> should be an array
of strings as defined in
L<http://swish-e.org/docs/swish-config.html#replacerules>.

=head2 BUILDARGS

Internal method. Allows for single argument to new().

=head2 BUILD

Parses the I<rules> and initializes the object.

=head2 rules

Get/set the array ref of parsed rules.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    return $class->$orig( rules => [@_] );
};

sub BUILD {
    my $self = shift;
    $self->{rules} = $self->_parse_rules( @{ $self->{rules} } );
}

sub _parse_rules {
    my $self = shift;
    my @rules;
    for my $r (@_) {
        my $rule = {};
        my ( $action, $target )
            = (
            $r =~ m/^\ *(replace|remove|prepend|append|regex)\s+(.+)$/is );
        $action = lc($action);
        if ( $action eq 'regex' ) {
            ($target) = shellwords($target);
            my ( $delim, $before, $after, $opts )
                = ( $target =~ m!^(.)(.+?)\1(.+?)\1(.+)$! );

            $rule->{target} = {
                delim  => $delim,
                before => $before,
                after  => $after,
                opts   => $opts,
            };

        }
        elsif ( $action eq 'replace' ) {
            my ( $before, $after ) = shellwords($target);

            #warn "before:$before after:$after";
            $rule->{target} = {
                before => $before,
                after  => $after,
            };

        }
        else {
            ( $rule->{target} ) = shellwords($target);
        }

        $rule->{action} = $action;
        $rule->{orig}   = $r;
        push @rules, $rule;
    }

    #warn "rules: " . dump \@rules;

    return \@rules;
}

=head2 apply( I<string> )

Apply the rules in the object against I<string>. Returns a modified
copy of I<string>.

=cut

sub apply {
    my $self = shift;
    my $str  = shift;
    if ( !defined $str ) {
        croak "string required";
    }

    #dump $self;

    for my $rule ( @{ $self->{rules} } ) {
        my $action = $rule->{action};
        my $target = $rule->{target};
        my $orig   = $rule->{orig};

        #warn "apply '$orig' to '$str'\n";

        if ( $action eq 'prepend' ) {
            $str = $target . $str;
        }
        if ( $action eq 'append' ) {
            $str .= $target;
        }
        if ( $action eq 'remove' ) {
            $str =~ s/$target//g;
        }
        if ( $action eq 'replace' ) {
            my $b = $target->{before};
            my $a = $target->{after};
            try {
                $str =~ s/$b/$a/g;
            }
            catch {
                die "Bad rule: $orig ($_)";
            };
        }
        if ( $action eq 'regex' ) {
            my $d    = $target->{delim};
            my $b    = quotemeta( $target->{before} );
            my $a    = quotemeta( $target->{after} );
            my $o    = $target->{opts};
            my $code = "\$str =~ s/$b/$a/$o";

            #warn "code='$code'\n";
            try {
                ## no critic (ProhibitStringyEval)
                eval "$code";
            }
            catch {
                die "Bad rule: $orig ($_)";
            }
        }

        #warn "$orig applied to '$str'\n";
    }
    return $str;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::ReplaceRules


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://swish-e.org/>, L<http://swish-e.org/docs/swish-config.html#replacerules>
