package IDS::Utils;
$IDS::Utils::VERSION = "1.0";

require Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw ();
our @EXPORT_OK = qw (&fh_or_stdout &uniq &to_fh &split_value);

use Carp qw(cluck carp confess);

=over

=item fh_or_stdout(filehandle)

=item fh_or_stdout(filehandle, destination)

=back

A utility function that returns either the filehandle passed in (if
defined) or a IO::Handle to STDOUT or the specified destination (which
is a fileno(filehandle)).

It would be nice to make this function more general (e.g., what about
stdin or stderr?  a specified file?).

=cut

sub fh_or_stdout {
    my $fh = shift;
    my $dest_fh = shift; # not required; default is STDOUT
    defined($dest_fh) or $dest_fh = fileno(STDOUT);

    unless (defined($fh)) {
        $fh = new IO::Handle;
        $fh->fdopen($dest_fh,"w") or
	    confess "Unable to fdopen STDOUT: $!\n";
    }
    return $fh;
}

=over

=item uniq(listref)

=item uniq(list)

Ensure no dups in the list (or list reference) we get.

The return value is either the list or a reference to a copy of the
list, depending on the calling context.  The list will have been sorted
as a side effect.

=back

=cut

sub uniq {
    my (@l, $i);

    if ($#_ == -1) {
        carp "uniq was not passed anything to work on!\n";
	return undef;
    }

    if (ref($_[0])) {
	my $lref = shift;
	@l = sort @$lref;
    } else {
	@l = sort @_;
    }

    for ($i=0; $i<$#l; $i++) {
        $l[$i] eq $l[$i+1] && splice(@l, $i+1, 1);
    }
    return wantarray ? @l : \@l;
}

=over

=item to_fh(filename)

=item to_fh(filename, method)

=item to_fh(filehandle)

Return a filehandle.  If the argument is a file name, we will open the
file with the method specified, for reading if unspecified.  If the
argument is a filehandle, it is simply returned.

=back

=cut

sub to_fh {
    my $arg = shift;
    my $method = shift || "<";
    my $fh;

    defined($arg) or confess "to_fh missing filename/filehandle argument";

    $fh = ref($arg) && $arg->isa("IO::Handle")
        ? $arg
	: (new IO::File("$method $arg") or confess "Cannot open $arg: $!\n");

    return $fh;
}

=over

=item split_value($name, $pattern, $value)

Split the value using the pattern given.  For each of the resulting
pieces, prepend "$name: ".  This function is used when there are a
collection of values for a given name (e.g., q-values, accept values).

=back

=cut

sub split_value {
    my ($name, $pattern, $value) = @_;
    my @pieces = ();
     
#    @pieces = map {$_ ? "$name: $_" : "BUG: undef in split_value '$value' split at '$pattern'"} split /$pattern/, $value;
    for my $part ( split /$pattern/, $value ) {
	next unless defined($part) && $part ne "";
	push @pieces, "$name: $part";
    }
#    @pieces = map {$_ ? "$name: $_" : undef} split /$pattern/, $value;
    for (my $i=0; $i <= $#pieces; $i++) {
	defined($pieces[$i]) && $pieces[$i] or
	    splice @pieces, $i, 1;
    }
    return @pieces;
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut


1;
