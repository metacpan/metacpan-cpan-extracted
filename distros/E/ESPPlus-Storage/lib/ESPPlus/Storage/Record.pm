package ESPPlus::Storage::Record;
use 5.006;
use strict;
use warnings;
use Carp 'confess';
use ESPPlus::Storage::Util;

BEGIN {
    for (qw(compressed
	    uncompressed
	    header_text)) {
	attribute_builder( $_, 'read only' );
    }

    attribute_builder( 'uncompress_function' );

    for ([qw[expected_length L]],
	 [qw[timestamp       U]],
	 [qw[application     A]]) {
	my $method_name = $_->[0];
	my $header_tag  = $_->[1];
	
	eval qq[
		sub $method_name {
		    my \$self = shift;
		    if ( exists \$self->{'$method_name'} ) {
			return \$self->{'$method_name'};
		    }
		    
		    my \$ht = \${\$self->{'header_text'}};
		    if ( \$ht =~ /$header_tag=(?>[^;]+);/ ) {
			return \$self->{'$method_name'} = 
			    substr( \$ht,
				    \$-[0] + 2,
				    \$+[0] - \$-[0] - 3 );
		    }
		    
		    return;
		}
		];
	confess( $@ ) if $@;
    }
}

sub new {
    my $class = shift;
    my $p     = shift;
    my $self  = bless { %$p }, $class;
    
    return $self;
}

sub body {
    my $self = shift;
    
    if ( exists $self->{'uncompressed'} ) {
	return $self->{'uncompressed'};
    }

    unless ( exists $self->{'compressed'} ) {
	confess "Record missing body!";
    }

    my $expt_len;
    # Inlined the ->expected_length method call here.
    if ( exists $self->{'expected_length'} ) {
	$expt_len = $self->{'expected_length'};
    } else {
	if( ${$self->{'header_text'}} =~ /L=(?>[^;]+);/ ) {
	    $expt_len = substr
		( ${$self->{'header_text'}},
		  $-[0] + 2,
		  $+[0] - $-[0] - 3 );
	} else {
	    $expt_len = undef;
	}
    }

    $self->{'uncompressed'} = 
	$self->{'uncompress_function'}( $self->{'compressed'},
					$expt_len );
    
    my $retr_len = length ${$self->{'uncompressed'}};
    unless ( $expt_len == $retr_len ) {
	confess "Uncompressed record length $retr_len did not match expected "
	    . "length $expt_len for record $self->{record_number}.";
    }
    
    return $self->{'uncompressed'};
}

sub header_length   { length ${$_[0]->{'header_text'}} }

1;

__END__

=head1 NAME

ESPPlus::Storage::Record - A single ESP+ Storage record

=head1 SYNOPSIS

 use ESPPlus::Storage;
 my $st = ESPPlus::Storage->new
     ( { filename => $Repository,
         uncompress_function => \&uncompress } );
 my $rd = $st->reader;
 
 while ( my $record = $rd->next_record ) {
     print $record->record_number,   "\t",
           $record->expected_length, "\n";
 }

=head1 DESCRIPTION

C<ESPPlus::Storage::Record> is an interface to individual ESP+ Storage
repository records. Mostly it exists to make the job of uncompressing the
internal .Z file easy, the other methods extract information from the record's
header.

=head1 CONSTRUCTOR

=over 4

=item new

 my $rc = ESPPlus::Storage::Record->new
     ( { header_text         => \ $header_text,
         compressed          => \ $record_body,
	 uncompress_function => \ &uncompress,
	 record_number       =>   $rec_num } );

This accepts the C<header_text>, C<record_number> and either a C<compressed>
and C<uncompress_function> parameter OR an C<uncompressed parameter>.

=back

=head1 PROPERTIES

=over 4

=item body

This returns the uncompressed content of the record. If the record has already
been uncompressed then it caches the inflated form.

=item compressed

This returns the compressed record (if it is stored).

=item uncompressed

This returns the stored uncomressed record. This is not populated automatically
and you should probably use the C<body> method instead.

=item header_text

This returns the original record headers.

=item header_length

This is the length of the headers.

=item expected_length

This returns the expected length of the uncompressed record. It is used as a
check to see whether the uncompression was successful or not.

=item timestamp

The record timestamp.

=item application

The ESP+ Storage repository name.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SEE ALSO

L<ESPPlus::Storage>

=cut


