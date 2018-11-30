package HTTP::Accept;

# ABSTRACT: Parse the HTTP header 'Accept'

our $VERSION = '0.03';

use Moo;

has string => ( is => 'ro', required => 1 );
has values => ( is => 'ro', lazy => 1, default => \&_parse_string );

sub match {
    my ($self, @values_to_check) = @_;

    @values_to_check = grep{ defined $_ && length $_ } @values_to_check;
    return '' if !@values_to_check;

    my @accepts = @{ $self->values || [] };
    return $values_to_check[0] if !@accepts;

    @values_to_check = map { lc $_ } @values_to_check;

    ACCEPT:
    for my $accept ( @accepts ) {
        return $values_to_check[0] if $accept eq '*/*';

        my ($cat, $type) = split /\//, $accept;

        VALUE:
        for my $value ( @values_to_check ) {
            return $value if $value eq $accept;

            my ($value_cat, $value_type) = split /\//, $value;

            next VALUE if $value_cat ne $cat;

            return $value if $type eq '*';
        }
    }

    return '';
}

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
 
    return { string => $args[0] }
        if @args == 1 && !ref $args[0];
 
    return $class->$orig(@args);
};

sub _parse_string {
    my ($self) = @_;

    my @accepts = split /\s*,\s*/, $self->string // '';
    my %weighted;

    for my $accept ( @accepts ) {
        my ($accept_name, $quality) = split /;/, $accept;

        $quality //= 'q=1';
        $quality   = 'q=1' if $quality !~ m{q=};

        my ($weight) = $quality =~ m{q=([^;]*)};
        push @{ $weighted{$weight} }, lc $accept_name;
    }

    my @accept_names = map{ @{ $weighted{$_} || [] } } sort { $b <=> $a }keys %weighted;

    return \@accept_names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Accept - Parse the HTTP header 'Accept'

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use HTTP::Accept;
    
    my $header         = 'text/html, application/json;q=0.5';
    my $accept_header  = HTTP::Accept->new( $header );
    
    # returns text/html
    my $use_accept     = $accept_header->match( qw(text/html application/json) );

=head1 ATTRIBUTES

=head2 string

The header string as passed to C<new>.

=head2 values

The given media types in the prioritized order.

  Header                            | Values
  ----------------------------------+----------------------------
  text/html, application/json;q=0.5 | text/html, application/json
  application/json;q=0.5, text/html | text/html, application/*
  application/*;q=0.5, text/html    | text/html, application/*
  */*                               | */*

=head1 METHODS

=head2 new

    my $header         = 'text/html, application/json;q=0.5';
    my $accept_header  = HTTP::Accept->new( $header );

=head2 match

    # header: 'text/html, application/json;q=0.5'
    my $accept = $accept_header->match('text/html');                     # text/html
    my $accept = $accept_header->match('application/json');              # application/json
    my $accept = $accept_header->match('application/json', 'text/html'); # text/html
    my $accept = $accept_header->match();                                # empty string
    my $accept = $accept_header->match(undef);                           # empty string
    my $accept = $accept_header->match('image/png');                     # empty string

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
