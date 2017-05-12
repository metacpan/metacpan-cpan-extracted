package ELF::Writer::Section;
use Moo 2;
use Carp;
use ELF::Writer;
use namespace::clean;

*VERSION= *ELF::Writer::VERSION;

# ABSTRACT: Object representing the fields of one section in an ELF file.


has name        => ( is => 'rw' );

our (%type_to_sym, %type_from_sym);
ELF::Writer::_init_enum(\%type_to_sym, \%type_from_sym,
	'null'     =>  0, # Ignore this section entry
	'progbits' =>  1, # Contents of section are program specific
	'symtab'   =>  2, # symbol table
	'strtab'   =>  3, # string table
	'rela'     =>  4, # relocation table with specific addends
	'hash'     =>  5, # symbol hash table
	'dynamic'  =>  6, # dynamic linking information
	'note'     =>  7, # various identification of file
	'nobits'   =>  8, # program-specific "pointer" using offset field.  has no length.
	'rel'      =>  9, # relocation table without specific addends
	'shlib'    => 10, # ??
	'dynsym'   => 11, # symbol table
	'num'      => 12, # ??
);

has type => ( is => 'rw', coerce => sub {
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


has flags       => ( is => 'rw' );

sub flag_write {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~1 | ($value? 1 : 0) )
		if defined $value;
	$self->flags & 1;
}

sub flag_alloc {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~2 | ($value? 2 : 0) )
		if defined $value;
	$self->flags & 2;
}

sub flag_execinstr {
	my ($self, $value)= @_;
	$self->flags( $self->flags & ~4 | ($value? 4 : 0) )
		if defined $value;
	$self->flags & 4;
}


has addr        => ( is => 'rw' );    
has offset      => ( is => 'rw' );
has size        => ( is => 'rw' );
has link        => ( is => 'rw' );
has info        => ( is => 'rw' );
has addralign   => ( is => 'rw' );
has entsize     => ( is => 'rw' );


has data        => ( is => 'rw' );
has data_start  => ( is => 'rw', default => sub { 0 } );

sub data_offset { $_[0]->offset + $_[0]->data_start }

has _index => ( is => 'rw' );
sub _name { "segment ".shift->_index }
sub _required_file_alignment { $_[0]->addralign || 1 }


sub BUILD {
	my ($self, $params)= @_;
	defined $params->{flag_write}
		and $self->flag_write($params->{flag_write});
	defined $params->{flag_alloc}
		and $self->flag_alloc($params->{flag_alloc});
	defined $params->{flag_execinstr}
		and $self->flag_execinstr($params->{flag_execinstr});
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

ELF::Writer::Section - Object representing the fields of one section in an ELF file.

=head1 VERSION

version 0.011

=head1 ATTRIBUTES (header fields)

The following are elf section header fields:

=head2 name

Pointer to name of this section within the Strings table. (.shstrtab)

TODO: auto-generate the string table if this is set to anything other than a number.

=head2 type, type_sym

Type of this section.  A 32-bit number, or one of: C<"null"> (or C<undef>), C<"progbits">,
C<"symtab">, C<"strtab">, C<"rela">, C<"hash">, C<"dynamic">, C<"note">, C<"nobits">, C<"rel">,
C<"shlib">, C<"dynsym">, C<"num">.

=head2 flags

32-bit flags.  Use the attributes below to access known flag bits.

=head2 flag_write

Read/write accessor for write bit of flags

=head2 flag_alloc

Read/write accesor for alloc bit of flags

=head2 flag_execinstr

Read/write accessor for execinstr bit of flags

=head2 addr

The address in the process's memory where this section gets loaded, or zero if
it doesn't.

=head2 offset

Location within the ELF file where this section is located.

=head2 size

Size (in bytes) of the section within the ELF file.  If the type of the
section is 'nobits' then this field is ignored and the section does not
occupy bytes of the ELF file.

=head2 link

Reference to another section, as an index into the section table.
Meaning depends on section type.

=head2 info

Extra info, depending on section type.

=head2 addralign

Required alignment for the L</addr> field.  Addr must be a multiple of this
value.  Values 0 and 1 both mean no alignment is required.

=head2 entsize

If the section holds a table of fixed-size entries, this is the size of each
entry.  Set to 0 otherwise.

=head1 ATTRIBUTES (user)

=head2 data

The data bytes of this section

=head2 data_start

Use this attribute to introduce padding between the start of the section and
the offset where your 'data' should be written.  This is mainly of use for
segments, but provided on sections for symmetry.

=head2 data_offset

Read-only sum of L</offset> and L</data_start>.  This is the file offset at
which your data scalar (if provided) will be written to the file.

=head1 METHODS

=head2 new

standard Moo constructor. Pass any attributes, *including* the flag aliases.

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
