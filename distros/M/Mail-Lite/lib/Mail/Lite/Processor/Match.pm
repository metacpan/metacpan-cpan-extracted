#===============================================================================
#
#         FILE:  Match.pm
#
#  DESCRIPTION:  Processor::Match match processor
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#===============================================================================

package Mail::Lite::Processor::Match;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;
use Digest::MD5 qw/md5_hex/;
use Carp qw/cluck/;

require Data::Dumper;

sub _dump {
    my @a = @_;
    my $dd = Data::Dumper->new(\@a);
    return $dd->Indent(1)->Terse(1)->Dump;
    #Data::Dumper->new(\@_)->Indent(1)->Terse(1)->Dump;
}

sub _match_rule {
    my ( $rule, $data ) = @_;

    my ( $message, $field ) = @$data;

    #warn _dump( $rule, $field, $message );

    my $matched = $message->{matched} ||= {};

    my $rule_hash = "$field:".($rule||'defined');

    if ( exists $matched->{ $rule_hash } ) {
	return 1 if $matched->{ $rule_hash };
	return 0;
    }
    else 
    {
	my $result;

	if ( ref $rule eq 'HASH' && exists $rule->{matcher} ) {
	
	    $result = _check_with_custom_processor( $message, $rule );
	}
	else {
	    if ( $field eq 'body' ) {
		$result = match_body( $message, $rule );
	    }
	    elsif ( my $checker = __PACKAGE__->can("match_$field") ) {
		#warn "Can match_$field";
		$result = $checker->( $message, $rule );
	    }
	    else {
		#warn "Can match_header_field: $field, $rule";
		$result = match_header_field($message, $field, $rule);
	    }
	}

	$matched->{ $rule_hash } = $result;

	return $result;
    }
}


sub _match_message {
    #warn _dump( @_ );
    my $rules = shift;
    my $message = shift;


    my $matched = $message->{matched} ||= {};

    #keys %$rules;
    foreach my $k (keys %$rules) {
	#while (my ($k, $v) = each %$rules) {
	my $v = $rules->{$k};

	my $rule_hash = "$k:".($v || 'defined');
	if ( exists $matched->{ $rule_hash } ){
	    next if $matched->{ $rule_hash };
#	    #keys %$rules;
	    return;
	} 
	else {
	    my $result = _recurse_conditions( \&_match_rule, $v, 
		[ $message, $k ]
	    );

#	    $matched->{ $rule_hash } = $result;

	    return unless $result;
	}
    }

    return 1;
}

sub _recurse_conditions {
    #open my $fh, '>>output.txt';
#    if ( ref $_[1] eq 'HASH' ) {
	#print $_[1], "\n";
	#print join (', ', exists $_[1]->{'AND'}, exists $_[1]->{'NOT'}, exists $_[1]->{'OR'}), "\n";
	#print tied( $_[1] ) ? 'tied' : 'untied', "\n";
	#print _dump( $_[1]->{'OR'} );
	#print $fh "Join:".join (', ', %{ $_[1] }), "\n";
#    } elsif ( ref $_[1] eq 'ARRAY' ) {
	#print $fh "Join:".join (', ', @{ $_[1] }), "\n";
#    } elsif ( not ref $_[1] ) {
	#print $fh $_[1], "\n";
#    }
    #close $fh;
    #warn ( ("".\@_) x 1024 );

    my $handler = shift;
    my $rule	= shift;
    my $data	= shift;

    ### $rule

    if (    ref $rule eq 'HASH'
	    and
	exists $rule->{'AND'} ||
	exists $rule->{'OR' } ||
	exists $rule->{'NOT'}
	    and
	scalar keys %$rule > 1
    ) {
	die q{Wrong keys in }
	._dump($rule).
	qq{\nYou should not mess up OR/AND/NOT with plain fields}.
	qq{\nSeparate them into different array members};

    }

    if ( ref $rule eq 'HASH' and exists $rule->{'AND'} ) {
	$rule = $rule->{'AND'};
    }

    if ( ref $rule eq 'ARRAY' ) {
	#warn 'AND: '.ref $data;
	foreach my $r ( @$rule ) {
	    #warn 'rule is: '.$r;
	    if ( ! _recurse_conditions( $handler, $r, $data ) ) {
		return 0;
	    }
	}

	#warn 'and: ',_dump $rule, $data;
	return 1;
    }

    if ( ref $rule eq 'HASH' and exists $rule->{'NOT'} ) {
#	warn 'NOT: '.ref $data;
	return ! _recurse_conditions( $handler, $rule->{'NOT'}, $data );
    }

    if ( ref $rule eq 'HASH' and exists $rule->{'OR'} ) {
	$rule = $rule->{'OR'};
	#warn 'OR: '.ref $data;
	#warn _dump $rule;

	#warn _dump $data->{matched};
	foreach my $r ( @$rule ) {
	    #warn 'oring: ', $handler eq \&_match_message;
	    if ( _recurse_conditions( $handler, $r, $data ) ) {
		#warn 'or: ',_dump $r, $data;
		return 1;
	    }
	}

	return 0;
    }

    #warn 'simply: '.ref $data;
    #warn _dump $data if ref $data eq 'Mail::Lite::Message';
    if ( $ENV{FAKE_THEM_ALL} ) {
#	print "faken saved: $ENV{FAKE_THEM_ALL}\n";
	#warn 'hash with: '.scalar (values %$rule) if ref $rule eq 'HASH';
    }


    #warn 'simply', $handler eq \&_match_rule;
    return $handler->( $rule, $data );
}

sub _check_with_custom_processor {
    my ($message, $rule) = @_;
    if ( not ref $rule->{matcher} eq 'CODE' ) {
	my ($package, $sub) = $rule->{matcher} =~ /(.*)::(.*)/;
	$package->require;

	{ 
	    no strict 'refs'; ## no critic
	    $rule->{matcher} = *{"$package\::$sub"}{CODE};
	}
    }

    return $rule->{matcher}->( $message, $rule );
}

our $match_text = \&_match_text;

sub match_body {
    my ( $message, $rule ) = @_;

    my $body = $message->{body};

    #warn "rule = $rule";
    @_ = ($body, $rule);
    no strict 'refs';
    goto &$match_text;

    #return _match_text( $body, $rule );
}

sub _match_subject { 
    my ( $message, $rule ) = @_;

    my $text = $message->{subject};

    #die "$text ::: $rule";
    #warn "rule = $rule";
    @_ = ($text, $rule);
    no strict 'refs';
    goto &$match_text;
    goto &{'_match_text'};

    #return _match_text( $text, $rule );
}

sub _match_from { 
    my ( $message, $rule ) = @_;

    my $text = $message->{from};

    #warn "rule = $rule";
    @_ = ($text, $rule);
    no strict 'refs';
    goto &$match_text;
    goto &{'_match_text'};

    #return _match_text( $text, $rule );
}

sub match_to {
    my ( $message, $rule ) = @_;;

    #warn "rule = $rule";
    my $msg_recipients = $message->recipients;
    foreach my $msg_to (@{$msg_recipients}) { 
	return 1 if _match_text( $msg_to, $rule );
    }

    return 0;
}

sub match_header_field {
    my ( $message, $field, $rule ) = @_;

    $field = 'subject' if $field eq 'subj';

    #my $value = $message->raw_header;

    my $value = exists $message->{ $field }
	?  $message->{ $field } : $message->header( $field );

    #die "$value, $field, $rule";
    #warn "rule = $rule";
    #die $value, $field, $rule;
    #return _match_text( $value, '(?im)^'.$field.':\s+[^\n]*'.$rule );
    @_ = ($value, $rule);
    no strict 'refs';
    goto &$match_text;
    goto &{'_match_text'};

    #return _match_text( $value, $rule );
}

our $rules;

sub _match_text {
    my ($text, $rule) = @_;

    ### $text
    ### $rule

    #warn "$text, $rule", " is ".$text =~ /$rule/;

    # Ð¿ÑƒÑÑ‚Ñ‹Ðµ Ð¿Ñ€Ð°Ð²Ð¸Ð»Ð° Ð´Ð»Ñ Ð¿Ñ€Ð¾Ð²ÐµÑ€ÐºÐ¸ ÑÑƒÑ‰ÐµÑÑ‚Ð²Ð¾Ð²Ð°Ð½Ð¸Ñ Ð¿Ð¾Ð»Ñ
    return 1 if defined $text && !defined $rule;

    return unless $text;

#    return $text =~ qr/$rule/;

#    if ( $rule =~ tr/()*\./()*\./ ) {
#	$rule = 0;
#    }

#    if ( index( $rule, "qr" ) != 0 ) {
#	return $text eq $rule;
#    }

    $rule = $rules->{$rule} ||= qr/$rule/;

    #warn "Don't matches";
    return $text =~ $rule;
}

# Ñîïîñòàâèòü ñîîáùåíèå ñ ïðàâèëîì
sub match {
    my ( $me, $processor, $message ) = @_;

    if ( not ref $message ) {
	die "Message is not ref: $message";
    }

    my $match_rules = $processor->{match_rules};

    if ( _recurse_conditions( \&_match_message, $match_rules, $message ) ) {
	#print '_recurse_conditions is ok', "\n";
	#warn _dump ( $match_rules );
	return OK;
    }

    return NEXT_RULE;
}

sub process {
    my $args_ref = shift;

    my ( $processor, $message ) = @$args_ref{ qw/processor input/ };

    #Mail::Lite::Processor::Match->require;

    return __PACKAGE__->match( $processor, $message );
}

=head1 

=head2 SYNOPSIS

* test

=cut

1;
