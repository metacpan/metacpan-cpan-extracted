package Math::SymbolicX::Calculator::Interface::Web::Server;
use strict;
use warnings;
use base qw(HTTP::Server::Simple::CGI);
use CGI::Ajax;

my $pjx = CGI::Ajax->new( 'process_new_input' => \&process_new_input );

our $Calc = Math::SymbolicX::Calculator::Interface::Web->new();

sub handle_request {
    my ($self, $cgi) = @_;
    my $html = $pjx->build_html( $cgi, \&Show_HTML );
    $html =~ s/^[^\n]*\n//; # header?!
    print $html;
    #warn $html;
    return($html);
}

sub Show_HTML {
    my $template = <<"HERE";
<HTML>
<head>
<title>Math::SymbolicX::Calculator::Interface::Web</title>
<style type="text/css">
<!--
textarea.input {
    margin-top:10px
}
span.input {
    font-family:"Courier",monospace;
    padding:4px;
    background:#EEEE00;
}
span.output {
    font-family:"Courier",monospace;
    color:white;
    background:#111177;
    padding:4px;
}
div.cell { margin-top:20px; margin-bottom:9px }
div.error {
    font-family:"Courier",monospace;
    color:black;
    background:#FF7777;
    padding:5px;
}
-->
</style>

<script type="text/javascript">
<!--
function apply_new_input() {
    var cmd = arguments[0];
    if (cmd.match("error")) {
        set_error(arguments[1]);
    }
    else if (cmd.match("new_input")) {
        set_error("");
        append_cell(arguments[1], arguments[2]);
    }
    else {
        set_error("Invalid AJAX command: '" + arguments[0] + "'");
    }
}

function append_cell(input, output) {
    var numberfield = document.getElementById("current_input_no");
    var number = numberfield.innerHTML;
    var ws = document.getElementById("worksheet");
    ws.innerHTML =
        ws.innerHTML
        + '<div class="cell" id="cell' 
        + number
        + '" ondblclick="toggle_edit_cell('
        + number
        + ')"><i>Input['
        + number
        + ']:</i><span class="input" id="in'
        + number
        + '">'
        + input
        + '</span><br/></div><i>Result['
        + number
        + ']:</i><span class="output" id="out'
        + number
        + '">'
        + output
        + '</span></div>'
    ;
    number++;
    numberfield.innerHTML = number;
}

function set_error(errstring) {
    document.getElementById('error').innerHTML = errstring;
}

function toggle_edit_cell(number) {
    var input = document.getElementById('in'+number);
    if (input.innerHTML.match(/<textarea/)) {
        var tarea = input.firstChild;
        inputstr = tarea.value;
        input.innerHTML = inputstr;
        reevaluate_cell(number);
    }
    else {
        input.innerHTML = '<textarea id="edit_cell" class="input">'
            + input.innerHTML
            + '</textarea>';
    }
}

var _temp_number;
function reevaluate_cell(number) {
    // HACK!!!
    _temp_number = number;
    process_new_input(['in'+number],[reevaluate_cell_inner]);
}

function reevaluate_cell_inner() {
    var cmd = arguments[0];
    var number = _temp_number;

    if (cmd.match("error")) {
        set_error(arguments[1]);
        var out = document.getElementById("out"+number);
        out.innerHTML = "<strong>== COULD NOT EXECUTE ==</strong>";
    }
    else if (cmd.match("new_input")) {
        set_error("");
        var out = document.getElementById("out"+number);
        out.innerHTML = arguments[2];
    }
    else {
        set_error("Invalid AJAX command: '" + arguments[0] + "'. This is a fatal internal error that is most certainly a bug in the application. Please restart!");
    }
}

//-->
</script>

</head>
<body>
<i>Enter [<span id="current_input_no">1</span>]:</i> <textarea class="input" id="new_input"></textarea>
<input
    value="Evaluate"
    type="submit"
    onClick="process_new_input( ['new_input'], [apply_new_input] );"
/>
<div id="error" class="error"></div>
<div id="worksheet"></div>
</body>
</HTML>
HERE
    return $template;
}

sub process_new_input {
    my $input = shift;

    my $output = $Calc->execute_expression($input);
    if ($output =~ /^ERROR:/) {
        warn $output;
        return('error', $output);
    }

    return('new_input', $input, $output);
}

1;
__END__
