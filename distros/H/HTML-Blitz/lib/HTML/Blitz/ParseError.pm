# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::ParseError;
use HTML::Blitz::pragma;
use overload fallback => 1, '""' => method (@) { $self->to_string };

our $VERSION = '0.07';

method new($class:
    :$src_name,
    :$src_ref,
    :$pos,
    :$msg,
    :$width = 1,
    :$alt_pos = undef,
    :$alt_msg = undef,
    :$alt_width = 1,
) {
    bless {@_}, $class
}

fun _context($src_ref, $pos) {
    my $n_line     = substr($$src_ref, 0, $pos) =~ tr/\n// + 1;
    my $line_start = rindex($$src_ref, "\n", $pos - 1) + 1;
    my $line_end   = index($$src_ref, "\n", $pos);
    $line_end      = length $$src_ref if $line_end == -1;
    my $s_line     = substr $$src_ref, $line_start, $line_end - $line_start;
    my $lpos       = $pos - $line_start;
    +{
        line_num => $n_line,
        col_num  => $lpos + 1,
        line     => $s_line,
        m_prefix => substr($s_line, 0, $lpos) =~ tr/ \t/ /cr,
    }
}

method location() {
    $self->{_location} //= _context $self->{src_ref}, $self->{pos}
}

method alt_location() {
    my $alt_pos = $self->{alt_pos};
    return undef if !defined $alt_pos;
    $self->{_alt_location} //= _context $self->{src_ref}, $alt_pos
}

method to_string() {
    my $loc = $self->location;
    my $alt_loc = $self->alt_location;
    "$self->{src_name}:$loc->{line_num}:$loc->{col_num}: error: $self->{msg}\n"
    . " |\n"
    . " | $loc->{line}\n"
    . " | $loc->{m_prefix}" . '^' x $self->{width} . "\n"
    . (!defined $alt_loc ? "" :
        "$self->{src_name}:$alt_loc->{line_num}:$alt_loc->{col_num}: ... $self->{alt_msg}\n"
        . " |\n"
        . " | $alt_loc->{line}\n"
        . " | $alt_loc->{m_prefix}" . '^' x $self->{alt_width} . "\n"
    )
}

1
