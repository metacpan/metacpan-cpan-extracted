%# $Id: editfield.mc,v 1.11 2008-02-07 11:15:27 mike Exp $
<%args>
$record		# Reference to a DB::Object::<something>
$field		# Field name, e.g. "id", "tag", "name"
$fulltype	# As RHS of a display_fields() element.
$newrecord
# Note that $fulltype (and $type) are NEVER virtual-field recipes
</%args>
<%perl>
my($UNUSED_link, $readonly, $type, $exclude) = $record->analyse_type($fulltype, $field);
$readonly = 0 if $newrecord && $field ne "id";
my $htmlclass = $record->type2class($type);
$type = [ qw(No Yes) ] if $type eq "b";	# booleans handled as enums
my $text = val2text($type, $record->field($field));
#warn "record='$record', field='$field', type='$type', readonly='$readonly', exclude='$exclude', text='$text'\n";

print qq[     <td class="td-e-$htmlclass">];
if ($newrecord && $exclude) {
    print "      [none]\n";
    print qq[     </td>\n];
    return;
}

if (ref $text eq "ARRAY" && ($readonly || $exclude)) {
    # List-fields can't be directly edited at the moment: instead,
    # you have to go to one of the linked-to object and change its
    # parent pointer.
    print "\n";
    print "      <ul>\n";
    foreach my $obj (@$text) {
	my $qtext = encode_entities($obj->render_name());
	my $class = $obj->class();
	my $value = $obj->id();
	print("       <li>",
	      qq[<a href="./edit.html?_class=$class&amp;id=$value">],
	      $qtext, "</a></li>\n");
    }
    print "      </ul>\n";
    print "     ";
    return;
}

my($linkclass, $linkto, $linkid, $linkfield) = $record->link($field);

if (ref $type eq "ARRAY") {
    # Enumeration
    print qq[<select name="$field">\n];
    my $currentval = $record->field($field);
    foreach my $val (0 .. @$type-1) {
	my $text = $type->[$val];
	my $qtext = encode_entities($text);
	my $maybe = "";
	$maybe = qq[ selected="selected"] if $val eq $currentval;
	print qq[        <option value="$val"$maybe>$qtext</option>\n];
    }
    print qq[</select>\n];
} elsif (defined $linkclass) {
    # Parent-link fields
    my $site = $m->notes("site");
    my($rs, $errmsg) = $site->search($linkclass);
    return $m->comp("error.mc", msg => $errmsg) if !defined $rs;
    my $n = $rs->count();
    #print "(link field $linkclass:$linkto = $linkid, $linkfield / n=$n)";
    print qq[<select name="$linkfield">\n];
    my @options;
    foreach my $i (1..$n) {
	my $rec = $rs->fetch($i);
	push @options, [ $rec->field($linkto), $rec->render_name() ];
    }

    @options = sort { $a->[1] cmp $b->[1] } @options;

    foreach my $ref (@options) {
	my($val, $text) = @$ref;
	my $qtext = encode_entities($text);
	my $maybe = "";
	$maybe = qq[ selected="selected"] if $val eq $linkid;
	print qq[        <option value="$val"$maybe>$qtext</option>\n];
    }
    print qq[</select>\n];
} else {
    # Simple text-field
    my $qtext = encode_entities($text);
    my $rtext = $readonly ? ' readonly="true" class="readonly"' : "";
    print qq[<input type="text"$rtext size="50" name="$field" value="$qtext"/>];
    print "</td>";
}


### This is the same function as in displayfield.mc -- if it remains
#   unchanged once link-editing is fixed, then it should be factored
#   out into an Object method.
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


</%perl>
