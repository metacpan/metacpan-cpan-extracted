package ELF::Writer::Segment;
use Moo 2;
use Carp;
use ELF::Writer;
use namespace::clean;

*VERSION= *ELF::Writer::VERSION;

# ABSTRACT: Object representing the fields of one program segment in an ELF file.


our (%type_to_sym, %type_from_sym);
ELF::Writer::_init_enum(\%type_to_sym, \%type_from_sym,
	'null'    => 0, # Ignored entry in program header table
	'load'    => 1, # Load segment into program address space
	'dynamic' => 2, # Dynamic linking information
	'interp'  => 3, # Specifies location of string defining path to interpreter
	'note'    => 4, # Specifies location of auxillary information
	'shlib'   => 5, # ??
	'phdr'    => 6, # Specifies location of the program header loaded into process image
);
has type => ( is => 'rw', default => sub { 1 }, coerce => sub {
	my $x= $type_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'type'"
});
sub type_sym {
	my $self= shift;
	$self->type($_[0]) if @_;
	my $v= $self->type;
	$type_to_sym{$v} || $v
}


has offset      => ( is => 'rw' );
has virt_addr   => ( is => 'rw' );    
has phys_addr   => ( is => 'rw' );

has filesize    => ( is => 'rw' );
*size= *filesize; # alias

has memsize     => ( is => 'rw' );


has flags       => ( is => 'rw', default => sub { 5 } );

sub flag_readable {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~1 | ($value? 1 : 0) )
		if defined $value;
	$self->flags & 1;
}

sub flag_writable {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~2 | ($value? 2 : 0) )
		if defined $value;
	$self->flags & 2;
}

sub flag_executable {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~4 | ($value? 4 : 0) )
		if defined $value;
	$self->flags & 4;
}

has align       => ( is => 'rw' );


has data        => ( is => 'rw' );
has data_start  => ( is => 'rw', default => sub { 0 } );

sub data_offset { $_[0]->offset + $_[0]->data_start }

# These are overwritten on each call to Writer->serialize
has _index => ( is => 'rw' );
sub _name { "segment ".shift->_index }
sub _required_file_alignment { $_[0]->align || 1 }

sub BUILD {
	my ($self, $params)= @_;
	defined $params->{flag_readable}
		and $self->flag_readable($params->{flag_readable});
	defined $params->{flag_writeable}
		and $self->flag_writeable($params->{flag_writeable});
	defined $params->{flag_executable}
		and $self->flag_executable($params->{flag_executable});
}


sub coerce {
	my ($class, $thing)= @_;
	return (ref $thing && ref($thing)->isa(__PACKAGE__))? $thing : $class->new($thing);
}

sub clone {
	my $self= shift;
	return bless { %$self }, ref $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Writer::Segment - Object representing the fields of one program segment in an ELF file.

=head1 VERSION

version 0.011

=head1 ATTRIBUTES (header fields)

The following are elf program header fields:

=head2 type, type_sym

Type of segment: C<"null"> (or C<undef>), C<"load">, C<"dynamic">, C<"interp">, C<"note">,
C<"shlib">, or C<"phdr">.  Defaults to C<"load">.

=head2 offset

Offset of this segment within the elf file

=head2 virt_addr

Address where this segment should be memory-mapped

=head2 phys_addr

Address where this segment should be loaded

=head2 filesize, size

Size of the segment within the elf file

=head2 memsize

Size of the segment after loaded into memory

=head2 flags

32-bit flags.  Use the accessors below to access the defined bits.
Defaults to readable and executable.

=head2 flag_readable

Read/write the C<readable> bit of flags

=head2 flag_writable

Read/write the C<writable> bit of flags

=head2 flag_executable

Read/write the C<executable> bit of flags.

=head2 align

Page size, for both the file and when loaded into memory (I think?)

=head1 ATTRIBUTES (user)

=head2 data

The payload of this segment (machine code, or etc)

=head2 data_start

Used for auto-aligning segments within the elf file.  This is the number of
bytes in the file which should come between L</offset> and your data.  Typical
use of this feature is to have the first segment start at offset 0 and include
the elf header, with data starting somehwere beyond it.  If this is zero (or
just less than the size of your elf header) then nearly a whole page will be
wasted within the file as it aligns the start of the data to a page boundary.

=head2 data_offset

Read-only sum of L</offset> and L</data_start>.  This is the file offset at
which your data scalar (if provided) will be written to the file.

=head1 METHODS

=head2 new

Standard Moo constructor. Pass any attributes, I<including> the flag bit aliases.

=head2 coerce

  $class->coerce($thing)

Returns C<$thing> if it is an instance of C<$class>, or passes $thing to the
constructor otherwise.

=head2 clone

Clone this instance.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
