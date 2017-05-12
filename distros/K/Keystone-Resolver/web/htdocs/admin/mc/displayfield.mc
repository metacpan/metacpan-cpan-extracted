%# $Id: displayfield.mc,v 1.3 2007-12-12 15:16:32 marc Exp $
<%args>
$context	# "s" = short form, "l" = long
$record		# Reference to a DB::Object::<something>
$field		# Field name, e.g. "id", "tag", "name"
$fulltype	# As RHS of a display_fields() element.
# Note that $fulltype (and $type) are NEVER virtual-field recipes
</%args>
<%perl>
die "unrecognised context '$context'" if !grep { $context eq $_ } qw(s l);
my($link, $UNUSED_readonly, $type) = $record->analyse_type($fulltype, $field);
$link &&= ($context eq "s");
my $htmlclass = $record->type2class($type);
my $text = val2text($type, $record->field($field));
#print STDERR "context='$context', record='$record', field='$field', type='$type', text='$text'\n";

print qq[     <td class="td-$context-$htmlclass">];
mumble($context, $record, $field, $type, $link, $text);
print "</td>";


sub val2text {
    my($type, $val) = @_;

    if (ref $val eq "ARRAY") {
	# Recursively apply to array values -- although the recursion
	# can never go down more than one level, since list-field
	# values are always lists of _objects_ rather than of
	# (potentially structured) values
	return [ map { val2text($type, $_) } @$val ];
    }

    return $type->[$val] if ref($type) eq "ARRAY"; # enum
    return $val if grep { $type eq $_ } qw(t c n); # text/code/number
    return $val ? "Yes" :" No" if $type eq "b";	# boolean
    return "type $type: $val";	# unrecognised
}


sub mumble {
    my($context, $record, $field, $type, $link, $text) = @_;

    if (ref $text eq "ARRAY") {
	print "\n";
	print "      <ul>\n";
	foreach my $obj (@$text) {
	    print "       <li>";
	    mumble($context, $obj, undef, $type, 1, $obj->render_name());
	    print "</li>\n";
	}
	print "      </ul>\n";
	print "     ";
	return;
    }

    my $linktext = "";
    if ($link) {
	# Link through to full display of this object
	$linktext = linktext($record->class(), id => $record->id());
    } elsif ($context eq "l") {
	# Link to full display of parent object
	my($linkclass, $linkto, $linkid) = $record->link($field);
	$linktext = linktext($linkclass, $linkto, $linkid)
	    if defined $linkclass;
    }
    
    print "$linktext", encode_entities($text), ($linktext ? "</a>" : "");
}


sub linktext {
    my($class, $field, $value) = @_;
    return qq[<a href="./record.html?_class=$class&amp;$field=$value">];
}
</%perl>
