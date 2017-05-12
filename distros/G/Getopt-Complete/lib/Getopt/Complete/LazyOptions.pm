package Getopt::Complete::LazyOptions;

our $VERSION = $Getopt::Complete::VERSION;

our $AUTOLOAD;

sub new {
    my ($class, $callback) = @_;
    return bless { callback => $callback }, $class;
}

sub AUTOLOAD {
    my ($c,$m) = ($AUTOLOAD =~ /^(.*)::([^\:]+)$/);
    return if $m eq 'DESTROY';

    my $self = shift;
    my $callback = $self->{callback};
    my @spec;
    if (ref($callback) eq 'SCALAR') {
        no strict;
        no warnings;
        my $class = $$callback;
        my $path  = $class;
        $path =~ s/::/\//g;
        $path .= '.pm.opts';
        my @possible = map { $_ . '/' . $path } @INC;
        my @actual = grep { -e $_ } @possible;
        #print STDERR ">> possible @possible\n\nactual @actual\n\n";
        my $spec;
        if (@actual) {
            my $data = `cat $actual[0]`;
            $spec = eval $data;
        }
        else {
#            print STDERR ">> redo $class!\n";
            local $ENV{GETOPT_COMPLETE_CACHE} = 1;
            eval "use $class";
            die $@ if $@;
            no strict;
            no warnings;
            $spec = ${ $class . '::OPTS_SPEC' };
            #print STDERR ">> got @spec\n";
        }
        @spec = @$spec;
    }
    else {
        @spec = $self->{callback}();
    }
    %$self = (
        sub_commands => [], 
        option_specs => {}, 
        completion_handlers => {}, 
        parse_errors => undef,
        %$self,
    );
    bless $self, 'Getopt::Complete::Options';
    $self->_init(@spec);
    $self->$m(@_);
}

1;

=pod

=head1 NAME

Getopt::Complete::LazyOptions - internal object used as a placeholder for unprocessed options

=head1 VERSION

This document describes Getopt::Complete::LazyOptions 0.26.

=head1 SYNOPSIS

    use Getopt::Complete (
        "foo=n" => [11,22,33],
        "bar=s" => "f",
        ">"     =>  sub {
                        my $values = [];
                        # code to generate completions for this option here...
                        return $values;
                    }
    );

=head1 DESCRIPTION

This class is used internally by Getopt::Complete::Options. 

=cut

