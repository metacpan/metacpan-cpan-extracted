use strict;
use warnings;

=head1 NAME

EJS::Template::Parser::Context - Implementation of EJS::Template::Parser

=cut

package EJS::Template::Parser::Context;
use base 'EJS::Template::Base';

use EJS::Template::Runtime;

my $states = {
    'INIT' => {
        key => 'INIT', method => '_in_init',
        js_open => '', js_close => '',
    },
    'TEXT' => {
        key => 'TEXT', method => '_in_text',
        js_open => 'print("', js_close => '");',
    },
    '<%' => {
        key => '<%'  , method => '_in_script',
        js_open => '', js_close => '',
    },
    '<%=' => {
        key => '<%=' , method => '_in_script',
        js_open => 'print(' , js_close => ');',
    },
};

=head1 Methods

=head2 new

Creates a new parser context.

=cut

sub new {
    my ($class, $config) = @_;
    my $self = $class->SUPER::new($config);
    
    $self->{stack} = [];
    $self->{result} = [];
    
    $self->{default_escape} = do {
        my $name = $self->config('escape') || '';
        
        if ($name eq '' || $name eq 'raw') {
            '';
        } else {
            $EJS::Template::Runtime::ESCAPES{$name} || '';
        }
    };
    
    $self->_push_state('INIT');
    return $self;
}

=head2 read_line

Parses a line.

=cut

sub read_line {
    my ($self, $line) = @_;
    
    while ($line =~ m{(.*?)((^\s*)?<%(?:(?:\s*:\s*\w+\s*)?=)?|%>(\s*?(?:\n|$))?|\\?["']|/\*|\*/|//|\n|$)}g) {
        my ($text, $mark, $left, $right) = ($1, $2, $3, $4);
        my $escape;
        
        if ($mark =~ s/<%\s*:\s*(\w+)\s*=/<%=/) {
            my $name = $1;
            $escape = $EJS::Template::Runtime::ESCAPES{$name} || '';
        } elsif ($mark eq '<%=') {
            $escape = $self->{default_escape};
        }
        
        $mark =~ s/\s+(<%=?)/$1/;
        $mark =~ s/(%>)\s+/$1/;
        
        my $opt = {
            left   => $left  ,
            right  => $right ,
            escape => $escape,
        };
        
        $self->_handle_token($text) if $text ne '';
        $self->_handle_token($mark, $opt) if $mark ne '';
    }
}

=head2 result

Retrieves the result (an array ref of the generated JavaScript texts).

=cut

sub result {
    my ($self) = @_;
    $self->_pop_state() until @{$self->{stack}} <= 1;
    return $self->{result};
}

sub _handle_token {
    my ($self, $token, $opt) = @_;
    my $method = $self->{stack}[-1]{state}{method};
    return $self->$method($token, $opt);
}

sub _top_key {
    my ($self) = @_;
    return $self->{stack}[-1]{state}{key};
}

sub _top_opt {
    my ($self) = @_;
    return $self->{stack}[-1]{opt} || {};
}

sub _append_result {
    my ($self, $text) = @_;
    push @{$self->{result}}, $text;
}

sub _push_state {
    my ($self, $state_key, $opt) = @_;
    my $state = $states->{$state_key};
    $self->_append_result($state->{js_open}) if $state->{js_open} ne '';
    my $entry = {state => $state, opt => $opt};
    push @{$self->{stack}}, $entry;
}

sub _pop_state {
    my ($self) = @_;
    my $entry = pop @{$self->{stack}};
    my $state = $entry->{state};
    $self->_append_result($state->{js_close}) if $state->{js_close} ne '';
}

sub _in_init {
    my ($self, $token, $opt) = @_;
    
    if ($token eq '<%') {
        if (defined $opt->{left}) {
            $opt->{ltrim} = {};
            
            if ($opt->{left} ne '') {
                $self->_append_result($opt->{left});
                $opt->{ltrim}{index} = $#{$self->{result}};
            }
        }
        
        $self->_push_state($token, $opt);
    } elsif ($token eq "<%=") {
        if (defined $opt->{left} && $opt->{left} ne '') {
            $self->_push_state('TEXT');
            $self->_append_result($opt->{left});
            $self->_pop_state();
        }
        
        $self->_push_state($token, $opt);
        
        if (my $escape = $opt->{escape}) {
            $self->_append_result(qq{EJS.$escape(});
        }
    } elsif ($token eq "\n") {
        $self->_push_state('TEXT');
        $self->_append_result("\\n");
        $self->_pop_state();
        $self->_append_result("\n");
    } else {
        $token =~ s/([\\"])/\\$1/g;
        $self->_push_state('TEXT');
        $self->_append_result($token);
    }
}

sub _in_text {
    my ($self, $token, $opt) = @_;
    
    if ($token eq '<%') {
        $self->_pop_state();
        $self->_push_state($token, $opt);
    } elsif ($token eq '<%=') {
        $self->_pop_state();
        $self->_push_state($token, $opt);
        
        if (my $escape = $opt->{escape}) {
            $self->_append_result(qq{EJS.$escape(});
        }
    } elsif ($token eq "\n") {
        $self->_append_result("\\n");
        $self->_pop_state();
        $self->_append_result("\n");
    } else {
        $token =~ s/([\\"])/\\$1/g;
        $self->_append_result($token);
    }
}

sub _in_script {
    my ($self, $token, $opt) = @_;
    
    if ($token eq '%>') {
        if (my $ltrim = $self->_top_opt->{ltrim}) {
            if (defined $opt->{right}) {
                if ($opt->{right} ne '') {
                    $self->_append_result($opt->{right});
                }
            } else {
                if (defined(my $idx = $ltrim->{index})) {
                    my $left = $self->{result}[$idx];
                    $self->{result}[$idx] = qq{print("$left");};
                }
            }
            
            $self->_pop_state();
        } else {
            if ($self->_top_opt->{escape}) {
                $self->_append_result(qq{)});
            }
            
            $self->_pop_state();
            
            my $right = $opt->{right};
            
            if (defined $right && $right ne '') {
                if ($right =~ s/\n$//) {
                    $self->_append_result(qq{print("$right\\n");\n});
                } else {
                    $self->_append_result(qq{print("$right");});
                }
            }
        }
    } else {
        $self->_append_result($token);
    }
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=item * L<EJS::Template::Parser>

=back

=cut

1;
