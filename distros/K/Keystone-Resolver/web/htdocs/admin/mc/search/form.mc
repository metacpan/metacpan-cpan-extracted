%# $Id: form.mc,v 1.7 2008-01-29 14:49:02 mike Exp $
% my $site = $m->notes("site");
<%args>
$_class
</%args>
<%perl>
my $fullclass = "Keystone::Resolver::DB::$_class";
my @fields = $fullclass->search_fields();
my @params = (submitted => (defined utf8param($r, "_submit")));
</%perl>
     <form method="get" action="">
      <p>
       Fill in as many or as few of the fields below as you like.
      </p>
      <table class="pinkform">
% while (@fields) {
%	my $name = shift @fields;
%	my $type = shift @fields;
%	if (ref $type) {
<& /mc/form/select.mc, @params, name => $name,
	label => $fullclass->label($name), size => $type,
	options => [ [ "", "(any)" ],
		     map { [ $_-1, $type->[$_-1] ] } 1..@$type ] &>
%	} elsif ($type =~ s/^[tn]//) {
<& /mc/form/textbox.mc, @params, name => $name,
	label => $fullclass->label($name), size => $type &>
%	} elsif ($type eq "b") {
<& /mc/form/checkbox.mc, @params, name => $name,
	label => $fullclass->label($name) &>
%	} elsif ($type eq "s") {
<& /mc/form/separator.mc &>
%	} else {
      <tr>
       <td colspan="2" class="error">
        Unknown search-field type '<% $type %>'
       </td>
      </tr>
%	}
% }
       <tr>
        <td></td>
        <td align="right" class="unpink">
	 <input type="submit" name="_submit" value="Search"/>
	 <input type="hidden" name="_class" value="<% $_class %>"/>
        </td>
       </tr>
      </table>
     </form>
% $m->comp("/mc/newlink.mc", _class => $_class);
