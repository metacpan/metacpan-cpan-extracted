package Language::LispPerl::Atom;
$Language::LispPerl::Atom::VERSION = '0.007';
use Moose;

use Language::LispPerl::Printer;
use Language::LispPerl::Logger;

our $id = 0;

has 'class' => ( is => 'ro', isa => 'Str', default => 'Atom' );
has 'type' => ( is => 'rw', isa => 'Str', required => 1 );

has 'value' => ( is => 'rw', default => '' );
has 'object_id' => ( is => 'ro', isa => 'Str', default => sub{ 'atom'.( $id++ ); } );
has 'meta_data' => ( is => 'rw' );
# An atom that is a function can have a context.
has 'context' => ( is => 'rw' );
has 'pos' => ( is => 'ro', default => sub{
                   return {
                       filename => "unknown",
                       line     => 0,
                       col      => 0
                   };
               });

sub to_hash{
    my ($self) = @_;
    return {
        class => $self->class(),
        type => $self->type(),
        value => Language::LispPerl::Printer::to_perl( $self->value() ),
        object_id => $self->object_id(),
        meta_data => Language::LispPerl::Printer::to_perl( $self->meta_data() ),
        pos => Language::LispPerl::Printer::to_perl( $self->pos() ),
        # Note that we dont persist the function contexts
        # This forbids the evaluation of closures in deflated evalers.
        __class => $self->blessed(),
    };
}

sub from_hash{
    my ($class, $hash) = @_;
    return $class->new({
        map{ $_ => Language::LispPerl::Reader::from_perl( $hash->{$_} ) } keys %$hash
    });
}


sub show {
    my $self   = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;

    #print $indent . "class: " . $self->{class} . "\n";
    print $indent . "type: " . $self->{type} . "\n";
    print $indent . "value: " . $self->{value} . "\n";
}

sub error {
    my $self = shift;
    my $msg  = shift;
    $msg .= " [";
    $msg .= Language::LispPerl::Printer::to_string($self);
    $msg .= "] @[file: " . $self->{pos}->{filename};
    $msg .= " ;line: " . $self->{pos}->{line};
    $msg .= " ;col: " . $self->{pos}->{col} . "]";
    Language::LispPerl::Logger::error($msg);
}


__PACKAGE__->meta()->make_immutable();
1;

