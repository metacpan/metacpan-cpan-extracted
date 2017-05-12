# $Id: cern.pm,v 1.1.1.1 1997/12/11 21:44:35 lstein Exp $
package HTTPD::GroupAdmin::Text::cern;
use Carp;
@ISA = qw(HTTPD::GroupAdmin::Text::_generic);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

$DLM = ": ";

sub _parseline {
    local($self,$fh,$_) = @_;
    clean(*_);
    my($key, $val) = split($DLM, $_, 2);
    while($val =~ /,\s*$/) {
	$_ = <$fh>; clean(*_);
	$val .= $_;
    }
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    join($DLM, $key,$val) . "\n";
}

sub list {
    return keys %{$_[0]->{_HASH}} unless $_[1]; #this isn't quite right yet
    $_[0]->{_HASH}{$_[1]};
}

sub clean { local(*_) = @_; chomp; s/^\s+//; s/\s+$/ /; }

1;

__END__

<URL:http://www.w3.org/hypertext/WWW/Daemon/User/Config/AccessAuth.html>

Group File

Group file contains declarations of groups containing users and other groups, 
with possibly an IP address template. 
Group declarations as viewed from top-level look like this: 

        groupname: item, item, item

The list of items is called a group definition. 
Each item can be a username, an already-defined groupname, or a
comma-separated list of user and group names in parentheses. 
Any of these can be followed by an at sign @ followed by either
a single IP address template, or a comma-separated list of IP address templates 
in parentheses. The following are valid group declarations: 

        authors: john, james
        trusted: authors, jim
        cern_people: @128.141.*.*
        hackers: marca@141.142.*.*, sanders@153.39.*.*,
                 (luotonen, timbl, hallam)@128.141.*.*,
                 cailliau@(128.141.201.162, 128.141.248.119)
        cern_hackers: hackers@128.141.*.*

