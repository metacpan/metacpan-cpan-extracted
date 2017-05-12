package HTML::Table::FromDatabase;

use 5.005000;
use strict;
no warnings 'uninitialized';
use base qw(HTML::Table);
use vars qw($VERSION);
use HTML::Table;

$VERSION = '1.11';

# $Id$

=head1 NAME

HTML::Table::FromDatabase - a subclass of HTML::Table to easily generate a HTML table from the result of a database query

=head1 SYNOPSIS

 my $sth = $dbh->prepare('select * from my_table')
    or die "Failed to prepare query - " . $dbh->errstr;
 $sth->execute() or die "Failed to execute query - " . $dbh->errstr;

 my $table = HTML::Table::FromDatabase->new( -sth => $sth );
 $table->print;

=head1 DESCRIPTION

Subclasses L<HTML::Table>, providing a quick and easy way to produce HTML
tables from the result of a database query.

I often find myself writing scripts which fetch data from a database and
present it in a HTML table; often resulting in pointlessly repeated code
to take the results and turn them into a table.

L<HTML::Table> itself helps here, but this module makes it even simpler.

Column headings are taken from the field names returned by the query, unless
overridden with the I<-override_headers> or I<-rename_headers> options.

All options you pass to the constructor will be passed through to HTML::Table,
so you can use all the usual L<HTML::Table> features.


=head1 INTERFACE

=over 4

=item new

Constructor method - consult L<HTML::Table>'s documentation, the only
difference here is the addition of the following parameters:

=over 4

=item C<-sth>

(required) a DBI statement handle which has been executed and is ready
to fetch data from

=item C<-callbacks>

(optional) specifies callbacks/transformations which should be applied as the
table is built up (see the L</CALLBACKS> section below).

=item C<-html>

(optional) can be I<escape> or I<strip> if you want HTML to be escaped
(angle brackets replaced with &lt; and &gt;) or stripped out with HTML::Strip.

=item C<-override_headers>

(optional) provide a list of names to be used as the column headings, instead of
using the names of the columns returned by the SQL query.  This should be an
arrayref containing the heading names, and the number of heading names must
match the number of columns returned by the query.

=item C<-rename_headers>

(optional) provide a hashref of oldname => newname pairs to rename some or all
of the column names returned by the query when generating the table headings.

=item C<-auto_pretty_headers>

(optional, boolean) - automatically make column names nicer for headings,
using titlecase and swapping underscores for spaces etc (e.g. C<first_name>
becomes C<First Name>)

=item C<-pad_empty_cells>

(optional, default 1) pad empty cells with an C<&nbsp;> to ensure they're 
rendered with borders appropriately.  Many browsers "skip" empty cells, leading 
to missing borders around them, which many people consider broken.  To stop
this, by default empty cells receive a non-breaking space as their content.  If
you don't want this behaviour, set this option to a false value.

=back

=cut

sub new {
    my $class = shift;
    
    my %flags = @_;
    my $sth = delete $flags{-sth};
    
    if (!$sth || !ref $sth || !$sth->isa('DBI::st')) {
        warn "HTML::Table::FromDatabase->new requires the -sth argument,"
            ." which must be a valid DBI statement handle.";
        return;
    }

    my $callbacks = delete $flags{-callbacks};
    if ($callbacks && ref $callbacks ne 'ARRAY') {
        warn "Unrecognised -callbacks parameter; "
            ."expected a arrayref of hashrefs";
        return;
    }

    my $row_callbacks = delete $flags{-row_callbacks};
    if ($row_callbacks && ref $row_callbacks ne 'ARRAY') {
        warn "Unrecognised -row_callbacks parameter; "
            . "expected an arrayref of coderefs";
        return;
    }

    my $override_headers = delete $flags{-override_headers};
    if ($override_headers && ref $override_headers ne 'ARRAY') {
        warn "Unrecognised -override_headers parameter; "
            ."expected an arrayref";
        return;
    }

    my $rename_headers = delete $flags{-rename_headers};
    if ($rename_headers && ref $rename_headers ne 'HASH') {
        warn "Unrecognised -rename_headers parameter; "
            ."expected a hashref";
        return;
    }

    $flags{-pad_empty_cells} = 1 unless exists $flags{-pad_empty_cells};

    my $auto_pretty_headers = delete $flags{-auto_pretty_headers};


    # if we're going to encode or escape HTML, prepare to do so:
    my $preprocessor;
    if (my $handle_html = delete $flags{-html}) {
        if ($handle_html eq 'strip') {
            eval "require HTML::Strip;";
            if ($@) {
                warn "Failed to load HTML::Strip - cannot strip HTML";
                return;
            }
            my $hs = new HTML::Strip;
            $preprocessor = sub { $hs->eof; return $hs->parse(shift) };
        } elsif ($handle_html eq 'encode' || $handle_html eq 'escape') {
            eval "require HTML::Entities;";
            if ($@) {
                warn "Failed to load HTML::Entities - cannot encode HTML";
                return;
            }
            $preprocessor = sub { HTML::Entities::encode_entities(shift); };
        } else {
            warn "Unrecognised -html option.";
            return;
        }
    }
    
    # Create a HTML::Table object, passing along any other options we were
    # given:
    my $self = HTML::Table->new(%flags);
    
    # Find the names;
    my @columns = @{ $sth->{NAME} };

    # Default to using the column names as headings, unless we've been given
    # an -override_headers or -rename_headers option (if we got the
    # -auto_pretty_headers option, prettify them somewhat):
    my @heading_names = @columns;
    for (@heading_names) {
        if (exists $rename_headers->{$_}) {
            $_ = $rename_headers->{$_};
        } elsif ($auto_pretty_headers) {
            $_ = _prettify($_);
        }
    }

    if ($override_headers) {
        if (@$override_headers != @heading_names) {
            warn "Incorrect number of header names in -override_headers option"
                ." - got " . @$override_headers . ", needed " .  @heading_names;
        }
        @heading_names = @$override_headers;
    }
    
    $self->addSectionRow('thead', 0, @heading_names);
    $self->setSectionRowHead('thead', 0, 1);
    
    # Add all the rows:
    row:
    while (my $row = $sth->fetchrow_hashref) {
        # First, if there are any row callbacks, call them:
        for my $callback (@$row_callbacks) {
            $callback->($row);
        }

        # If the callback undefined $row, we should skip it:
        next row if !defined $row;

        # Now, work through each field
        my @fields;
        for my $column (@columns) {
            my $value = $row->{$column};

            if ($preprocessor) {
                $value = $preprocessor->($value);
            }


            # If we have a callback to perform for this field, do it:
            for my $callback (@$callbacks) {
                # See what we need to match against, and if it matches, call
                # the specified transform callback to potentially change the
                # value.
                if (exists $callback->{column}) {
                    if (_callback_matches($callback->{column}, $column)) {
                        $value = _perform_callback(
                           $callback, $column, $value, $row
                        );
                    }
                }
                if (exists $callback->{value}) {
                    if (_callback_matches($callback->{value}, $value)) {
                        $value = _perform_callback(
                            $callback, $column, $value, $row
                        );
                    }
                }
            }

            # If the value is empty, turn it into a non-breaking space to make
            # the cell still display correctly (otherwise it looks ugly):
            $value = '&nbsp;' if $value eq '' && $flags{-pad_empty_cells};
            
            # Add this field to the list to deal with:
            push @fields, $value;
        }
        
        $self->addRow(@fields);
    }
    
    # All done, re-bless into our class and return
    bless $self, $class;
    return $self;
};

# Abstract out the different kind of matches (regexp, coderef or straight
# scalar)
sub _callback_matches {
    my ($match, $against) = @_;
    if (ref $match eq 'Regexp') {
        return $against =~ /$match/;
    } elsif (ref $match eq 'CODE') {
        return $match->($against);
    } elsif (ref $match) {
        # A reference to something we don't understand:
        warn "Unrecognised callback match [$match]";
        return;
    } else {
        # Must be a straight scalar
        return $match eq $against;
    }
}

# A callback spec matched, so perform any callback it requests, and apply
# any transformation it described:
sub _perform_callback {
    my ($callback, $column, $value,$row) = @_;

    # Firstly, if there's a callback to perform, we call it (but don't
    # care what it returns):
    if (exists $callback->{callback} and ref $callback->{callback} eq 'CODE')
    {
        $callback->{callback}->($value, $row);
    }

    # Now, look for a transformation we might have to perform:
    if (!exists $callback->{transform}) {
        # We don't have a transform to perform, so just return the value
        # unchanged:
        return $value;
    }
    if (ref $callback->{transform} ne 'CODE') {
        warn "Unrecognised transform action";
        return $value;
    }

    # OK, apply the transformation to the value:
    return $callback->{transform}->($value, $row);
}

# lowercase input first to work on input that is already all uppercase
sub _prettify {
    $_=lc($_); s{_}{ }g; s{\b(\w)}{\u$1}g; $_;
}

1;
__END__;

=back

=head1 CALLBACKS

=head2 Per-cell callbacks

You can pass an arrayref of hashrefs describing callbacks to be performed as
the table is built up, which can modify the data before the table is produced.

Each callback receives the value and, as of 0.04, the $row hashref (normally
you will only want to look at the value, but occasionally I've found cases
where the callback needs to see the rest of the row, for various reasons).

This can be very useful; one example use-case would be turning the values in
a column which contains URLs into clickable links:

 my $table = HTML::Table::FromDatabase->new(
    -sth => $sth,
    -callbacks => [
        {
            column => 'url',
            transform => sub { $_ = shift; qq[<a href="$_">$_</a>]; },
        },
    ],
 );

You can match against the column name using a key named C<column> in the hashref
(as illustrated above) or against the actual value using a key named C<value>.

You can pass a straight scalar to compare against, a regex (using qr//), or
a coderef which will be executed to determine if it matches.

You pass a coderef to be called for matching cells via the C<transform> key.
You can use C<callback> instead if you want your coderef to be called but its
return value to be discarded (i.e. you don't intend to modify the value, but do
something else).

Another example - displaying all numbers to two decimal points:

 my $table = HTML::Table::FromDatabase->new(
    -sth => $sth,
    -callbacks => [
        {
            value => qr/^\d+$/,
            transform => sub { return sprintf '%.2f', shift },
        },
    ],
 );

It is hoped that this facility will allow the easiness of quickly creating
a table to still be retained, even when you need to do things with the data
rather than just displaying it exactly as it comes out of the database.

=head2 Per-row callbacks

You can also supply callbacks which operate on an entire row at a time with
the C<-row_callbacks> option, which simply takes an arrayref of coderefs, each
of which will be called in turn, will receive the row hashref as its first
parameter, and can modify the row in whatever way is desired.

  my $table = HTML::Table::FromDatabase->new(
      -sth => $sth,
      -row_callbacks => [
          sub {
            my $row = shift;
            # Do things with $row here
          },
      ],
  ):

If a row callback sets the C<$row> hashref to undef, that row will be skipped.

A more in-depth, if somewhat contrived, example:

  my $table = HTML::Table::FromDatabase->new(
      -sth => $sth,
      -row_callbacks => [
          sub {
            my $row = shift;
            if ($row->{name} eq 'Bob') {
                # Hide this row
                $row = undef;
            } elsif ($row->{name} eq 'John') {
                # John likes to be called Jean these days:
                $row->{name} = 'Jean';
            }
          },
      ],
  );


=head1 DEPENDENCIES

L<HTML::Table>, obviously :)

L<HTML::Strip> is required if you use the C<< -html => 'strip' >> option.

L<HTML::Entities> is required if you use the C<< -html => 'encode' >> option.


=head1 AUTHOR

David Precious, E<lt>davidp@preshweb.co.ukE<gt>

Feel free to contact me if you have any comments, suggestions or bugs to
report.

=head1 THANKS

Thanks to Ireneusz Pluta for reporting bug with -override_headers /
-rename_headers option and supplying patch in RT ticket #50164.

Thanks to Jared Still (jkstill) for amending the automatic column name
prettification to lowercase column names first, so Oracle users with their
uppercase columns can still have nice headings.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2016 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.
