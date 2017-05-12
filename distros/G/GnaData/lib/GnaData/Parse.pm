use strict;
use IO::Handle;
use English;

=pod
GnaData::Parse
=cut

package GnaData::Parse;

sub new {
    my $proto = shift;
    my $class =  ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $self->{'input_handle'} = IO::Handle->new();
    $self->{'input_handle'}->fdopen(fileno(STDIN), "r");

    $self->{'output_handle'} = IO::Handle->new();
    $self->{'output_handle'}->fdopen(fileno(STDOUT), "w");

    $self->{'start_entry'} = "";
    $self->{'end_entry'} = "";

    $self->{'extract_data'} = [];
    
    $self->{'start_parse'} = "";
    $self->{'end_parse'} = "";

    $self->{'remove_tags_list'} = 
	["strong", "font", "body", "b", "tt", "ul", "li", "i", "em",
	 "hr", "input", "html", "blockquote",
	 "p", "br", "nobr", "td", "tr", "a", "table", "u",
	 "dd", "dt", "img", "div", "center", "!--", "span"];
    return $self;
}

sub parse {
    my ($self) = @_;
    my ($in_entry) = 0;
    my ($in_parse) = 0;
    my ($line) = "";
    my ($start_entry) = $self->{'start_entry'};
    my ($end_entry) = $self->{'end_entry'};

    $self->{'current_entry'} = "";

    if ($self->{'start_parse'} eq "") {
	$in_parse = 1;
    }

    while ($line = $self->{'input_handle'}->getline()) {
	$self->extract_data($line,
			    $self->{'extract_list'});
	$self->{'state'} = "";
	if (!$in_parse &&
	    $line =~ m!$self->{'start_parse'}!i) {
	    $self->{'state'} = "start_parse";
	} elsif ($in_parse &&
	    $line =~ m!$self->{'end_parse'}!i) {
	    $self->{'state'} = "end_parse";
	} elsif ($in_parse &&
		 defined ($line) 
		 && $line =~ m!$start_entry!i) {
	    $self->{'state'} = "start_entry";
	} elsif ($in_parse &&
		 $in_entry &&
		 $end_entry ne "" && 
		 $line =~ m!$end_entry!i) {
	    $self->{'state'} = "end_entry";
	} elsif (! m!^\#! && $in_entry) {
	    $self->{'state'} = "read";
	}

	if (defined($self->{'parse_extension'})) {
	    &{$self->{'parse_extension'}}($self, $line);
	}
	
	if ($self->{'state'} eq "start_parse") {
	    $in_parse = 1;
	} elsif ($self->{'state'} eq "end_parse") {
	    if ($in_entry) {
		$self->{'current_entry'} .= $line;
		$self->print_entry($self->{'current_entry'});
	    }
	    $in_parse = 0;
	    $in_entry = 0;
	    $self->{'current_entry'} ="";
	} elsif ($self->{'state'} eq "start_entry") {
	    if ($in_entry) {
		$self->print_entry($self->{'current_entry'});
	    }	
	    $in_entry = 1; 
	    $self->{'current_entry'} = $line;
	} elsif ($self->{'state'} eq "end_entry") {
	    $in_entry = 0; 
	    $self->{'current_entry'} .= $line;
	    $self->print_entry($self->{'current_entry'});
	    $self->{'current_entry'}="";
	}  elsif ($self->{'state'} eq "read") {
	    $self->{'current_entry'} .= $line;
	}
    }

    if ($in_parse && $in_entry) {
	$self->print_entry($self->{'current_entry'});
    }
}

sub parse_entry {
    my ($self, $entry) = @_;
    $entry =~ s!\r!!gi;
    $entry =~ s!\n!\n   !gi;
    $entry =~ s!&nbsp;! !gi;
    if (defined($self->{'preprocess'})) {
	$entry = &{$self->{'preprocess'}}($self, $entry);
    }
    if ($entry =~ m/^\s*$/) {
	return "";
    }

    $entry = 
	$self->substitute_fields($entry, 
				   $self->{'substitute_list'});
    $entry = 
	&remove_tags($entry, $self->{'remove_tags_list'});

# Convert currencies (remember that we are international)
    $entry =~ s!\$!US\$!g;

# Add fields to the end

    $entry = $self->transform_entry ($entry,
				     $self->{'extract_data'});

# Remove excess blank space

    $entry =~ s!\n\s*\n!\n!gi;
    $entry =~ s!(\S)\s*\n!$1\n!g;
    
# convert high orderr characters to entities
    $entry =~ s!([\x7f-\xff])\s*!"\&\#" . ord($1). "\;"!ge;
    if ($entry =~ m/^\s*$/) {
	return "";
    }

    $entry = $self->transform_entry($entry, $self->{'transform_list'});
    $entry = "\n" . $entry;
    if (defined($self->{'postprocess'})) {
	$entry = &{$self->{'postprocess'}}($self, $entry);
    }


    return $entry;
}

sub dump_list {
    my ($self, $list) = @_;
    my ($item);
    $self->print("\n# Dumping list\n");
    foreach $item (@{$list}) {
	my ($field) = $item->[0];
	my ($func) = $item->[1];
	$self->print("\n# $field $func\n");
    }
}

sub transform_entry {
    my ($self, $entry, $transform_list) = @_;
    my (@fields) = ();
    my ($item);
    my (%field_values) = ();
    $self->split_entry($entry, \@fields, \%field_values);
    foreach $item (@{$transform_list}) {
	my ($field) = $item->[0];
	my ($func) = $item->[1];
# Note that here I mean exists and not undefined.  I only add the item to
# the field list if the hash value has never been defined
	if (!exists($field_values{$field})) {
	    push (@fields, $field);
	}	    
	if (ref($func) eq "CODE") {
	    $field_values{$field} =
		&$func(\%field_values); 
	    } else {

		$field_values{$field} = 
		    $func;
	    }
    }
    return $self->join_entry(\@fields, \%field_values);
}

sub split_entry {
    my ($self, $entry, $listref, $hashref) = @_;
    my ($line);
    my ($current_field) = ".header";

    foreach $line (split(/\n/, $entry)) {
	if ($line =~ m/^(\S+)\s+(.*)\s*$/) {
	    $current_field = $1;
	    push (@{$listref}, $current_field);
	    $hashref->{$current_field} = $2;
	} elsif ($line =~ m/^(\S+)\s*$/) {
	    $current_field = $1;
	    $hashref->{$current_field} = "";
	    push (@{$listref}, $current_field);
	} elsif ($current_field ne "" &&
		 $line !~ m/^\s*$/) {
	    $line =~ s/^\s+/ /gi;
	    if ($hashref->{$current_field} ne "") {
		$hashref->{$current_field} .= "\n";
	    }
	    $hashref->{$current_field} .= $line;
	}
    }
}

sub join_entry {
    my ($self, $listref, $hashref) = @_;
    my (@list) = ();
    my ($item);
    foreach $item (@{$listref}) {
	if ($item eq ".header") {
	    push(@list, "$hashref->{$item}");
	} else {
	    if (defined($hashref->{$item})) {
		push(@list, "$item   $hashref->{$item}");
	    }
	}
    }
    return join("\n", @list);
}

sub print_entry {
    my ($self, $entry) = @_;
    $self->print("\n" . $self->parse_entry($entry));
}

sub print {
    my ($self, $s) = @_;
    $self->{'output_handle'}->print($s);
}

sub entry_bounds {
    my ($self, $start, $end) = @_;
    $self->{'start_entry'} = $start;
    $self->{'end_entry'} = $end;
}

sub parse_bounds {
    my ($self, $start, $end) = @_;
    $self->{'start_parse'} = $start;
    $self->{'end_parse'} = $end;
}

sub extract_data {
    my ($self, $line, $extract_list) = @_;
    my ($item);
  loop:
    foreach $item (@$extract_list) {
	my ($field) =  $item->[0];
	
	if ($field ne ""
	    && $line =~ m!\s*$item->[1]!is) {
	    my ($value) = $1;
	    my ($item1);
	    my ($i) = 0;
	    foreach $item1 (@{$self->{'extract_data'}}) {
		if ($item1->[0] eq $field) {
		    $self->{'extract_data'}->[$i]->[1] = $value;
		    next loop;
		} 
		$i++;
	    }
	    push (@{$self->{'extract_data'}},
		  [$field, $value]);
	}
    }
}


sub extract_list {
    my ($self, $extract) = @_;
    $self->{'extract_list'} = $extract;
}

sub parse_extension {
    my ($self, $parse_extension) = @_;
    $self->{'parse_extension'} = $parse_extension;
}

sub substitute_list {
    my ($self, $substitute) = @_;
    $self->{'substitute_list'} = $substitute;
}

sub transform_list {
    my ($self, $clean) = @_;
    $self->{'transform_list'} = $clean;
}

sub remove_tags_list {
    my ($self, $remove_tags) = @_;
    $self->{'remove_tags_list'} = $remove_tags;
}

sub preprocess {
    my ($self, $preprocess) = @_;
    $self->{'preprocess'} = $preprocess;
}

sub process_line {
    my ($self, $process_line) = @_;
    $self->{'process_line'} = $process_line;
}

sub input_handle {
    my ($self) = shift;
    my ($inh) = shift;
    $self->{'input_handle'} = $inh;

}

sub output_handle {
    my ($self, $outh) = @_;
    $self->{'output_handle'} = $outh;
}


# This is a subroutine to do uncapitalizations

sub uncap {
    my($out) = @_;
    local ($_);
    my($return) = "";
    my(@list) = ();
    $out =~ s/^\s+//g;
    foreach (split(/\s+/, $out))  {
        /VLSI/ && next;
        /^[IVX]+$/ && next;
        y/A-Z/a-z/;
        /^(.)(.*)$/;
        my($up) = $1;
        my($down) = $2;
        $up =~ tr/a-z/A-Z/;
        push (@list, "$up$down");
    }
    return join(" ", @list);
}

sub remove_tags {
    my($entry, $tag_list) = @_;
    my($tag);
    foreach $tag (@{$tag_list}) {
	$entry =~ s!</*$tag(\s[^>]+)*>!!gi;
    }
    return $entry;
}

sub append_lines {
   my($entry, $line_list) = @_;
   my($line);
   foreach $line (@{$line_list}) {
       
       $entry =~ s!\s*$!\n$line->[0]   $line->[1]\n!i;
   }
   return $entry;
}

sub uncap_fields {
    my ($list_ref) = @_;
    my ($item);
    foreach $item (@$list_ref) {
	s/((^|\n)$item\s+)([^\n]+?(\n\s+[^\n]+?)*(\n|$))/ $1 . &uncap($3) . "\n"/se;
}
}
sub substitute_fields {
    my($self, $entry, $list_ref) = @_;
    my($item);
    my ($returnval) = "";
    foreach $item (@$list_ref) {
	if ($item->[0] ne ""
	    && $entry =~ m!\s*$item->[1]!is) {
		$returnval .= $::PREMATCH . "\n";
		$entry = $::POSTMATCH;
		eval "\$returnval .= \"$item->[0]   $item->[2]\"";
	    }
    }

    $returnval .= $entry;
    return $returnval;
}

1;













