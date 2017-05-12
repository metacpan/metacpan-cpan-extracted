package Lim::RPC::Value;

use common::sense;
use Carp;

use Lim ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item STRING

=item INTEGER

=item BOOL

=item BASE64

=item OPT_REQUIRED

=item OPT_NOTEMPTY

=back

=cut

our $VERSION = $Lim::VERSION;

sub STRING (){ 'string' }
sub INTEGER (){ 'integer' }
sub BOOL (){ 'bool' }
sub BASE64 (){ 'base64' }

our %TYPE = (
    STRING() => STRING,
    INTEGER() => INTEGER,
    BOOL() => BOOL,
    BASE64() => BASE64
);
our %XSD_TYPE = (
    STRING() => 'xsd:string',
    INTEGER() => 'xsd:integer',
    BOOL() => 'xsd:boolean',
    BASE64() => 'xsd:base64Binary'
);
our %XMLRPC_TYPE = (
    STRING() => 'string',
    INTEGER() => 'int',
    BOOL() => 'boolean',
    BASE64() => 'base64'
);

sub OPT_REQUIRED (){ 0x00000001 }
sub OPT_NOTEMPTY (){ 0x00000002 }

our %OPTIONS = (
    'required' => OPT_REQUIRED,
    'notEmpty' => OPT_NOTEMPTY
);

our %NEGATIVE_OPTIONS = (
    'optional' => OPT_REQUIRED,
    'empty' => OPT_NOTEMPTY
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = scalar @_ > 1 ? ( @_ ) : ( textual => $_[0] );
    my $self = {
        options => OPT_REQUIRED | OPT_NOTEMPTY
    };
    
    if (exists $args{textual}) {
        foreach (split(/\s+/o, lc($args{textual}))) {
            if (exists $TYPE{$_}) {
                if (exists $self->{type}) {
                    confess __PACKAGE__, ': type already defined';
                }
                $self->{type} = $_;
            }
            elsif (exists $OPTIONS{$_}) {
                $self->{options} |= $OPTIONS{$_};
            }
            elsif (exists $NEGATIVE_OPTIONS{$_}) {
                $self->{options} &= ~$NEGATIVE_OPTIONS{$_};
            }
            else {
                confess __PACKAGE__, ': unknown RPC value setting "'.$_.'"';
            }
        }
    }
    else {
        unless (defined $args{type}) {
            confess __PACKAGE__, ': No type specified';
        }
        unless (exists $TYPE{$args{type}}) {
            confess __PACKAGE__, ': Invalid type specified';
        }
        
        $self->{type} = $args{type};

        if (defined $args{options}) {
            unless (ref($args{options}) eq 'ARRAY') {
                confess __PACKAGE__, ': Invalid options specified';
            }
            
            foreach (@{$args{options}}) {
                if (exists $OPTIONS{$_}) {
                    $self->{options} |= $OPTIONS{$_};
                }
                elsif (exists $NEGATIVE_OPTIONS{$_}) {
                    $self->{options} &= ~$NEGATIVE_OPTIONS{$_};
                }
                else {
                    confess __PACKAGE__, ': Unknown RPC value option "'.$_.'"';
                }
            }
        }
    }
    
    unless (exists $self->{type}) {
        confess __PACKAGE__, ': no type defined';
    }

    bless $self, $class;
}

sub DESTROY {
    my ($self) = @_;
}

=head2 type

=cut

sub type {
    $_[0]->{type};
}

=head2 xsd_type

=cut

sub xsd_type {
    $XSD_TYPE{$_[0]->{type}};
}

=head2 xmlrpc_type

=cut

sub xmlrpc_type {
    $XMLRPC_TYPE{$_[0]->{type}};
}

=head2 required

=cut

sub required {
    $_[0]->{options} & OPT_REQUIRED ? 1 : 0;
}

=head2 comform

=cut

sub comform {
    my ($self, $value) = @_;
    
    # TODO validate type
    
    if (($self->{options} & OPT_NOTEMPTY)) {
        if (!defined $value or $value !~ /$\s*^/o) {
            return 0;
        }
    }
    
    return 1;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Value
