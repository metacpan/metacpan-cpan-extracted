// Various JavaScript samples put together from the Internet

var rows = prompt("How many rows for your multiplication table?");
var cols = prompt("How many columns for your multiplication table?");
if(rows == "" || rows == null)
	rows = 10;
if(cols== "" || cols== null)
	cols = 10;
createTable(rows, cols);
function createTable(rows, cols)
{
	var j=1;
	var output = "<table border='1' width='500' cellspacing='0'cellpadding='5'>";
	for(i=1;i<=rows;i++)
	{
		output = output + "<tr>";
		while(j<=cols)
		{
			output = output + "<td>" + i*j + "</td>";
			j = j+1;
		}
		output = output + "</tr>";
		j = 1;
	}
	output = output + "</table>";
	document.write(output);
}

var divs = new Array();
divs[0] = "errFirst";
divs[1] = "errLast";
divs[2] = "errEmail";
divs[3] = "errUid";
divs[4] = "errPassword";
divs[5] = "errConfirm";
function validate()
{
	var inputs = new Array();
	inputs[0] = document.getElementById('first').value;
	inputs[1] = document.getElementById('last').value;
	inputs[2] = document.getElementById('email').value;
	inputs[3] = document.getElementById('uid').value;
	inputs[4] = document.getElementById('password').value;
	inputs[5] = document.getElementById('confirm').value;
	var errors = new Array();
	errors[0] = "<span style='color:red'>Please enter your first name!</span>";
	errors[1] = "<span style='color:red'>Please enter your last name!</span>";
	errors[2] = "<span style='color:red'>Please enter your email!</span>";
	errors[3] = "<span style='color:red'>Please enter your user id!</span>";
	errors[4] = "<span style='color:red'>Please enter your password!</span>";
	errors[5] = "<span style='color:red'>Please confirm your password!</span>";
	for (i in inputs)
	{
		var errMessage = errors[i];
		var div = divs[i];
		if (inputs[i] == "")
			document.getElementById(div).innerHTML = errMessage;
		else if (i==2)
		{
			var atpos=inputs[i].indexOf("@");
			var dotpos=inputs[i].lastIndexOf(".");
			if (atpos<1 || dotpos<atpos+2 || dotpos+2>=inputs[i].length)
				document.getElementById('errEmail').innerHTML = "<span style='color: red'>Enter a valid email address!</span>";
			else
				document.getElementById(div).innerHTML = "OK!";
		}
		else if (i==5)
		{
			var first = document.getElementById('password').value;
			var second = document.getElementById('confirm').value;
			if (second != first)
				document.getElementById('errConfirm').innerHTML = "<span style='color: red'>Your passwords don't match!</span>";
			else
				document.getElementById(div).innerHTML = "OK!";
		}
		else
			document.getElementById(div).innerHTML = "OK!";
	}
}

function finalValidate()
{
	var count = 0;
	for(i=0;i<6;i++)
	{
		var div = divs[i];
		if(document.getElementById(div).innerHTML == "OK!")
		count = count + 1;
	}
	if(count == 6)
		document.getElementById("errFinal").innerHTML = "All the data you entered is correct!!!";
}

function trigger()
{
	document.getElementById("hover").addEventListener("mouseover", popup);

	function popup()
	{
		alert("Welcome to my WebPage!!!");
	}
}

/* This script and many more are available free online at
The JavaScript Source!! http://www.javascriptsource.com
Created by: Sandeep Gangadharan | http://www.sivamdesign.com/scripts/ */
function runBanner() {
    // change the name of the image below
  document.getElementById('banner').src='large_img.gif';
}

  // change the number below to adjust the time the image takes to load
window.setTimeout("runBanner()", 5000);

// sets up database of links - SECTION A1
var muresources="";
muresources["classical"]= "<A HREF='http://net.com/classical.file1'>Meditative classical music<A><P><A HREF='http://net.com/classical.file2'>Provoking classical music<A>";
muresources["rock"] = "<A HREF='http://net.com/rock.file1'>Popular rock music<A><P><A HREF='http://net.com/rock.file2'>Exciting rock music<A>";
muresources["ethnic"] = "<A HREF='http://net.com/mexican.file1'>Mexican music<A><P><A HREF='http://net.com/Indian.file2'>Indian music<A>";

function getLink() {
// constructs unique page using name and choice of music - SECTION A.2
temp = muresources[choice];
temp2 = "<TITLE>Custom Links</TITLE><H3>" +document.m.pername.value+", here are somelinks for you</H3><P>"+temp;
}

function writeIt(){
// creates new window to display page - SECTION A.3
diswin = window.open();
diswin.document.open();
diswin.document.write(temp2);
diswin.document.close()
}

function doAll(){
// master routine calls other functions - SECTION A.4
getLink();
writeIt()
}

//assigns value to variable
test ="What is all this?";

// opens document and uses methods to modify text characteristics
document.open();
document.write(test.bold()+"<P>");
document.write(test.fontsize(7)+"<P>");
document.write(test.fontcolor("red")+"<P>");
document.write(test.toUpperCase()+"<P>");

//assigns multiple characteristics to text
document.write(test.italics().fontsize(6).fontcolor("green")+"<P>");
document.open();

// Puts the text to scroll into variable called sent - SECTION A
// uses length propert to assess its length and put into variable slen
// initalizes a,b,n, and subsent variables
var sent = "This is a demonstration of a banner moving from the left to right. It makes use of the substring property of Javascript to make an interesting display";
var slen = sent.length;
var siz = 25;
var a = -3, b = 0;
var subsent = "x";

// Creates a function to capture substrings of sent - SECTION B
function makeSub(a,b) {
subsent = sent.substring(a,b) ;
return subsent;
}

//Creates a function that increments the indexes of the substring - SECTION C
//each time and calls the makeSub() function to geneate strings
//a indicates start of substring and siz indicates size of string required
function newMake() {
a = a + 3;
b = a + siz;
makeSub(a,b);
return subsent;
}

//function uses loop to get changing substrings of target - SECTION D
//repeatedly calls newMake to get next substring
//uses setTimeout() command to arrange for substrings to display
// at specified times
function doIt() {
for (var i = 1; i <= slen ; i++) {
setTimeout("document.z.textdisplay.value = newMake()", i*300);
setTimeout("window.status = newMake()", i*300);
}
}

function Html()
{
	let ul = document.getElementById("myUL");
    let li = ul.getElementsByTagName("li");
	let x  = document.getElementById("myButton");
	return function()
	{
		return x.onclick = function()
		{
			for(let i = 0; i < li.length ;i ++)
				{
					li[i].style.color="red";
					li[i].style.listStyleType = "none";
				}
		}
	}
}
let html = new Html();
html();

//investment evaluation section
function future_value_of_investment(principal, rate, period,freq,input_answer_id) {
    var mrate = rate / 100;
    var mPrincipal = principal;
            var mPeriod = period;
            if (freq == "yearly") { mrate /= 1; mPeriod *= 1; }
            else if (freq == "semi-annually") { mrate /= 2; mPeriod *= 2; }
            else if (freq == "quartally") { mrate /= 3; mPeriod *= 3; }
            else if (freq== "monthly") { mrate /= 12; mPeriod *= 12; }
            else if (freq == "weekly") { mrate /= 52; mPeriod *= 52; }
            else if (freq == "daily") { mrate /= 365; mPeriod *= 365; }
            mrate += 1;
            var mratepow =Math.pow(mrate, mPeriod);
            document.getElementById(input_answer_id).value= mPrincipal * mratepow;

}

function simpleInterest(principal, rate, period, input_answer_id) {
    var mrate = rate / 100;
    document.getElementById(input_answer_id).value = principal * mrate * period;
}



function sinkingFund( accruedAmount,rate, period,freq,input_answer_id)
{
            var maccruedamount = accruedAmount;
 var mrate = rate /100;
if (freq == "yearly") { mrate /= 1; period*= 1; }
else if (freq == "semi-annually") { mrate /= 2; period *= 2; }
else if (freq == "quartally") { mrate /= 3; period *= 3; }
else if (freq == "monthly") { mrate /= 12; period *= 12; }
else if (freq == "weekly") { mrate /= 52; period *= 52; }
else if (freq == "daily") { mrate /= 365; period *= 365; }
maccruedamount *= mrate;
mrate += 1;
var ratePow = Math.pow(mrate, period);
ratePow -= 1;
document.getElementById(input_answer_id).value = maccruedamount / ratePow;
}



function Amortization( debt, rate, period,freq,input_answer_id)
{

            var mdebt = debt;
var mrate = rate / 100;
var mperiod = period;
if (freq == "yearly") { mrate /= 1; mperiod *= 1; }
else if (freq == "semi-annually") { mrate /= 2; mperiod *= 2; }
else if (freq == "quartally") { mrate /= 3; mperiod *= 3; }
else if (freq == "monthly") { mrate /= 12; mperiod *= 12; }
else if (freq == "weekly") { mrate /= 52; mperiod *= 52; }
else if (freq == "daily") { mrate /= 365; mperiod *= 365; }
var myrate = mrate;
mrate += 1;
var ratePow = 1-Math.pow(mrate, -mperiod);

var Numerator = mdebt * myrate;
document.getElementById(input_answer_id).value = Numerator/ratePow;
}


function PayBackPeriod( principal, cashInflow,input_answer_id)
{

    document.getElementById(input_answer_id).value = principal / cashInflow;
}


function addcashinflow(cashinflow, rate, period) {

    var mCashInflow = cashinflow;
    var mrate = rate / 100;
    var mperiod = period;
     return mCashInflow / Math.Pow(mrate + 1, mperiod);


}



function annuity_future_value(periodic_payment, rate, period,freq,input_answer_id)
{
    var _periodic_payment = periodic_payment;
var mRate = rate / 100;
if (freq == "yearly") { mRate /= 1; period *= 1; }
else if (freq == "semi-annually") { mRate /= 2; period *= 2; }
else if (freq == "quartally") { mRate /= 3; period *= 3; }
else if (freq == "monthly") { mRate /= 12; period *= 12; }
else if (freq == "weekly") { mRate /= 52; period *= 52; }
else if (freq == "daily") { mRate /= 365; period *= 365; }
var myRate =mRate;
myRate += 1;
var RatePow = Math.pow(myRate, period)-1;
_periodic_payment *= RatePow;
document.getElementById(input_answer_id).value = _periodic_payment / mRate;
}

function present_value_of_investment(future_value, rate, period, freq, input_answer_id) {
    var mrate = rate / 100;
    var _future_value = future_value;
    var mPeriod = period;
    if (freq == "yearly") { mrate /= 1; mPeriod *= 1; }
    else if (freq == "semi-annually") { mrate /= 2; mPeriod *= 2; }
    else if (freq == "quartally") { mrate /= 3; mPeriod *= 3; }
    else if (freq == "monthly") { mrate /= 12; mPeriod *= 12; }
    else if (freq == "weekly") { mrate /= 52; mPeriod *= 52; }
    else if (freq == "daily") { mrate /= 365; mPeriod *= 365; }
    mrate += 1;
    var mratepow = Math.pow(mrate, mPeriod);
    document.getElementById(input_answer_id).value = _future_value / mratepow;
}

//Financial ratio section

function acid_ratio(current_asset, inventory, current_liability, input_answer_id) {
    var liquid = current_asset - inventory;
    document.getElementById(input_answer_id).value= liquid/current_liability;
}


 function current_ratio(current_asset, current_liability, input_answer_id){
     document.getElementById(input_answer_id).value = current_asset/current_liability;
 }


 function gross_profit_margin(net_sale, gross_profit, input_answer_id){
     document.getElementById(input_answer_id).value = gross_profit / net_sale;
 }

 function net_profit_margin(net_sale, net_profit,input_answer_id) {
     document.getElementById(input_answer_id).value = net_profit / net_sale;
 }

 function return_on_equity(net_income, equity, input_answer_id) {
     document.getElementById(input_answer_id).value = profit_after_tax / equity;
 }

 function return_on_cap_employed(earning_before_int_tax, cap_employed, input_answer_id) {
     document.getElementById(input_answer_id).value = earning_before_int_tax / cap_employed;
 }

 function debt_to_asset(total_liability, total_asset, input_answer_id) {
     document.getElementById(input_answer_id).value = total_liability / total_asset;
 }

 function debt_to_equity(total_debt, equity, input_answer_id) {
     document.getElementById(input_answer_id).value = total_debt / equity;

 }

 function inventory_turnover(net_sale, inventory, input_answer_id) {
     document.getElementById(input_answer_id).value = net_sale / inventory;
 }

 function asset_turnover(net_sale, total_asset, input_answer_id) {
     document.getElementById(input_answer_id).value = net_sale / total_asset;
 }

 function employee_turnover(net_sale,employee, input_answer_id) {
     document.getElementById(input_answer_id).value = net_sale / employee;
 }

// this script got from www.javascriptfreecode.com-Coded by: Krishna Eydatoula

// Set the number of snowflakes (more than 30 - 40 not recommended)
var snowmax=35;

// Set the colors for the snow. Add as many colors as you like
var snowcolor=new Array("#aaaacc","#ddddFF","#ccccDD");

// Set the fonts, that create the snowflakes. Add as many fonts as you like
var snowtype=new Array("Arial Black","Arial Narrow","Times","Comic Sans MS");

// Set the letter that creates your snowflake (recommended:*)
var snowletter="*";

// Set the speed of sinking (recommended values range from 0.3 to 2)
var sinkspeed=0.6;

// Set the maximal-size of your snowflaxes
var snowmaxsize=22;

// Set the minimal-size of your snowflaxes
var snowminsize=8;

// Set the snowing-zone
// Set 1 for all-over-snowing, set 2 for left-side-snowing
// Set 3 for center-snowing, set 4 for right-side-snowing
var snowingzone=3;

///////////////////////////////////////////////////////////////////////////
// CONFIGURATION ENDS HERE
///////////////////////////////////////////////////////////////////////////


// Do not edit below this line
var snow=new Array();
var marginbottom;
var marginright;
var timer;
var i_snow=0;
var x_mv=new Array();
var crds=new Array();
var lftrght=new Array();
var browserinfos=navigator.userAgent;
var ie5=document.all&&document.getElementById&&!browserinfos.match(/Opera/);
var ns6=document.getElementById&&!document.all;
var opera=browserinfos.match(/Opera/);
var browserok=ie5||ns6||opera;

function randommaker(range) {
	rand=Math.floor(range*Math.random());
    return rand;
}

function initsnow() {
	if (ie5 || opera) {
		marginbottom = document.body.clientHeight;
		marginright = document.body.clientWidth;
	}
	else if (ns6) {
		marginbottom = window.innerHeight;
		marginright = window.innerWidth;
	}
	var snowsizerange=snowmaxsize-snowminsize;
	for (i=0;i<=snowmax;i++) {
		crds[i] = 0;
    	lftrght[i] = Math.random()*15;
    	x_mv[i] = 0.03 + Math.random()/10;
		snow[i]=document.getElementById("s"+i);
		snow[i].style.fontFamily=snowtype[randommaker(snowtype.length)];
		snow[i].size=randommaker(snowsizerange)+snowminsize;
		snow[i].style.fontSize=snow[i].size;
		snow[i].style.color=snowcolor[randommaker(snowcolor.length)];
		snow[i].sink=sinkspeed*snow[i].size/5;
		if (snowingzone==1) {snow[i].posx=randommaker(marginright-snow[i].size);}
		if (snowingzone==2) {snow[i].posx=randommaker(marginright/2-snow[i].size);}
		if (snowingzone==3) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/4;}
		if (snowingzone==4) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/2;}
		snow[i].posy=randommaker(2*marginbottom-marginbottom-2*snow[i].size);
		snow[i].style.left=snow[i].posx;
		snow[i].style.top=snow[i].posy;
	}
	movesnow();
}

function movesnow() {
	for (i=0;i<=snowmax;i++) {
		crds[i] += x_mv[i];
		snow[i].posy+=snow[i].sink;
		snow[i].style.left=snow[i].posx+lftrght[i]*Math.sin(crds[i]);
		snow[i].style.top=snow[i].posy;

		if (snow[i].posy>=marginbottom-2*snow[i].size || parseInt(snow[i].style.left)>(marginright-3*lftrght[i])){
			if (snowingzone==1) {snow[i].posx=randommaker(marginright-snow[i].size);}
			if (snowingzone==2) {snow[i].posx=randommaker(marginright/2-snow[i].size);}
			if (snowingzone==3) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/4;}
			if (snowingzone==4) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/2;}
			snow[i].posy=0;
		}
	}
	var timer=setTimeout("movesnow()",50);
}

for (i=0;i<=snowmax;i++) {
	document.write("<span id='s"+i+"' style='position:absolute;top:-"+snowmaxsize+"'>"+snowletter+"</span>");
}
if (browserok) {
	window.onload=initsnow;
}

//    Script Editor:   Howard Chen
//    Browser Compatible for the script: IE 3.0 or Higher
//                                       Netscape 2.0 or Higher
//    This script is free as long as you keep its credits
/*The way this works is the converter converts the number
into the smallest unit in the converter, in this case it will
be gram, and then it converts the unit fram gram to other units.*/
function nofocus()
{
document.convert.InUnit.focus()
}
var gValue = 1;
var kgValue = 1000;
var ounceValue = 28.3495;
var lbValue = 453.592;
var tValue = 907184;
function toCM()
{
var i = document.convert.unit.selectedIndex;
var thisUnit = document.convert.unit.options[i].value;
if (thisUnit == "G")
        {
document.convert.g.value = document.convert.InUnit.value;
        }
else if(thisUnit == "KG")
        {
document.convert.g.value = document.convert.InUnit.value * kgValue;
        }
else if(thisUnit == "OUNCE" )
        {
document.convert.g.value = document.convert.InUnit.value * ounceValue;
        }
else if(thisUnit == "LB" )
        {
document.convert.g.value = document.convert.InUnit.value * lbValue;
        }
else if(thisUnit == "T" )
        {
document.convert.g.value = document.convert.InUnit.value * tValue;
        }
toAll();
}
function toAll()
{
var m = document.convert.g.value;
document.convert.kg.value = m / kgValue;
document.convert.ounce.value = m / ounceValue;
document.convert.lb.value = m / lbValue;
document.convert.t.value = m / tValue;
}


var Cost, GST, PST, Grand_Total;

function tally()
        {
        Cost = 0;
        if (document.orderform.Item1.checked) { Cost = Cost + 26.15;    }
        if (document.orderform.Item2.checked) { Cost = Cost + 26.10;    }
        if (document.orderform.Item3.checked) { Cost = Cost + 26;               }
        if (document.orderform.Item4.checked) { Cost = Cost + 26;               }
        if (document.orderform.Item5.checked) { Cost = Cost + 26.44;    }
        if (document.orderform.Item6.checked) { Cost = Cost + 26.01;    }
        if (document.orderform.Item7.checked) { Cost = Cost + 26;               }
        if (document.orderform.Item8.checked) { Cost = Cost + 26;               }
       if (document.orderform.Item9.checked) {  Cost = Cost + 25;               }

        GST = (Cost * 0.07);
        PST = (Cost * 0.07);

        Cost = dollar(Cost);
        GST = dollar(GST);
        PST = dollar(PST);
        Grand_Total = parseFloat(Cost) + parseFloat(GST) + parseFloat(PST);
        Grand_Total = dollar(Grand_Total);

        document.orderform.Total.value = "$" + Cost;
        document.orderform.GST.value = "$" + GST;
        document.orderform.PST.value = "$" + PST;
        document.orderform.GrandTotal.value = "$" + Grand_Total;
        }

function dollar (amount)
{
        amount = parseInt(amount * 100);
        amount = parseFloat(amount/100);
        if (((amount) == Math.floor(amount)) && ((amount - Math.floor (amount)) == 0))
        {
                amount = amount + ".00";
                return amount;
        }
        if ( ((amount * 10) - Math.floor(amount * 10)) == 0)
        {
                amount = amount + "0";
                return amount;
        }
        if ( ((amount * 100) - Math.floor(amount * 100)) == 0)
        {
                amount = amount;
                return amount;
        }
        return amount;
}


function Del(Word) {
a = Word.indexOf("<");
b = Word.indexOf(">");
len = Word.length;
c = Word.substring(0, a);
if(b == -1)
b = a;
d = Word.substring((b + 1), len);
Word = c + d;
tagCheck = Word.indexOf("<");
if(tagCheck != -1)
Word = Del(Word);
return Word;
}
function Check() {
ToCheck = document.form.text.value;
Checked = Del(ToCheck);
document.form.text.value = Checked;
alert("This form is not set to submit anywhere so you will stay here.  But please do notice that the text box's contents have been \"filtered\".");
return false;
}


function checkNum(data) {      // checks if all characters
var valid = "0123456789.";     // are valid numbers or a "."
var ok = 1; var checktemp;
for (var i=0; i<data.length; i++) {
checktemp = "" + data.substring(i, i+1);
if (valid.indexOf(checktemp) == "-1") return 0; }
return 1;
}


function dollarAmount(form, field) { // idea by David Turley
Num = "" + eval("document." + form + "." + field + ".value");
dec = Num.indexOf(".");
end = ((dec > -1) ? "" + Num.substring(dec,Num.length) : ".00");
Num = "" + parseInt(Num);

var temp1 = "";
var temp2 = "";

if (checkNum(Num) == 0) {
alert("This does not appear to be a valid number.  Please try again.");
}
else {

if (end.length == 2) end += "0";
if (end.length == 1) end += "00";
if (end == "") end += ".00";

var count = 0;
for (var k = Num.length-1; k >= 0; k--) {
var oneChar = Num.charAt(k);
if (count == 3) {
temp1 += ",";
temp1 += oneChar;
count = 1;
continue;
}
else {
temp1 += oneChar;
count ++;
   }
}
for (var k = temp1.length-1; k >= 0; k--) {
var oneChar = temp1.charAt(k);
temp2 += oneChar;
}
temp2 = "$" + temp2 + end;
eval("document." + form + "." + field + ".value = '" + temp2 + "';");
   }
}


function isValidDate(dateStr) {
// Checks for the following valid date formats:
// MM/DD/YY   MM/DD/YYYY   MM-DD-YY   MM-DD-YYYY
// Also separates date into month, day, and year variables

var datePat = /^(\d{1,2})(\/|-)(\d{1,2})\2(\d{2}|\d{4})$/;

// To require a 4 digit year entry, use this line instead:
// var datePat = /^(\d{1,2})(\/|-)(\d{1,2})\2(\d{4})$/;

var matchArray = dateStr.match(datePat); // is the format ok?
if (matchArray == null) {
alert("Date is not in a valid format.");
return false;
}
month = matchArray[1]; // parse date into variables
day = matchArray[3];
year = matchArray[4];
if (month < 1 || month > 12) { // check month range
alert("Month must be between 1 and 12.");
return false;
}
if (day < 1 || day > 31) {
alert("Day must be between 1 and 31.");
return false;
}
if ((month==4 || month==6 || month==9 || month==11) && day==31) {
alert("Month "+month+" doesn't have 31 days!");
return false;
}
if (month == 2) { // check for february 29th
var isleap = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
if (day>29 || (day==29 && !isleap)) {
alert("February " + year + " doesn't have " + day + " days!");
return false;
   }
}
return true;  // date is valid
}
//  End -->


ax=0;
function viewtable() {
 ax=Math.round(Math.random()*26);
 alphaArray=new Array("a", "n", "b", "d", "f", "h", "{", "i", "l", "v", "x", "z", "I", "J", "M", "N", "o", "O", "R", "S", "T", "U", "m", "6", "^", "u", "_", "[", "]");
 table="<table align=\"center\" border=\"0\" cellspacing=\"5\" cellpadding=\"1\"><tr>";
 j=1;
  for ( i = 99 ; i >= 0 ; i-- ) {
   a=Math.round(Math.random()*26);
   if(i%9 == 0 &&  i < 89)
   a=ax;
   table+="<td class=\"num\">"+i+"</td><td class=\"symbols\">"+alphaArray[a]+"</td>";
   if(j%10 == 0) table+="</tr><tr>"; j++;
  } table+="</table>";
  sym.innerHTML=table;
 sh.innerHTML="";
}
function show() {
 sh.innerHTML=alphaArray[ax];
 sym.innerHTML="<center>Guess? :) <a href=\"javascript:viewtable()\">Repeat</a></center>";
}


function fmtPrice(value) {
result="$"+Math.floor(value)+".";
var cents=100*(value-Math.floor(value))+0.5;
result += Math.floor(cents/10);
result += Math.floor(cents%10);
return result;
}
function compute() {
var unformatted_tax = (document.forms[0].cost.value)*(document.forms[0].tax.value);
document.forms[0].unformatted_tax.value=unformatted_tax;
var formatted_tax = fmtPrice(unformatted_tax);
document.forms[0].formatted_tax.value=formatted_tax;
var cost3= eval( document.forms[0].cost.value );
cost3 += eval( (document.forms[0].cost.value)*(document.forms[0].tax.value) );
var total_cost = fmtPrice(cost3);
document.forms[0].total_cost.value=total_cost;
}
function resetIt() {
document.forms[0].cost.value="19.95";
document.forms[0].tax.value=".06";
document.forms[0].unformatted_tax.value="";
document.forms[0].formatted_tax.value="";
document.forms[0].total_cost.value="";
}
// End -->



/*
JavaScript dice (by Website Abstraction, http://wsabstract.com)
Over 200+ free scripts here!
*/

//preload the six images first
var face0=new Image();
face0.src="d1.gif";
var face1=new Image();
face1.src="d2.gif";
var face2=new Image();
face2.src="d3.gif";
var face3=new Image();
face3.src="d4.gif";
var face4=new Image();
face4.src="d5.gif";
var face5=new Image();
face5.src="d6.gif";

function throwdice(){
//create a random integer between 0 and 5
var randomdice=Math.round(Math.random()*5);
document.images["mydice"].src=eval("face"+randomdice+".src");
}


<!--
function gpacalc()
{
//define valid grades and their values
var gr = new Array(9);
var cr = new Array(9);
var ingr = new Array(5);
var incr = new Array(5);

// define valid grades and their values
var grcount = 11;
gr[0] = "A+";
cr[0] = 5;
gr[1] = "A";
cr[1] = 4;
gr[2] = "A-";
cr[2] = 3.66;
gr[3] = "B+";
cr[3] = 3.33;
gr[4] = "B";
cr[4] = 3;
gr[5] = "B-";
cr[5] = 2.66;
gr[6] = "C+";
cr[6] = 2.33;
gr[7] = "C";
cr[7] = 2;
gr[8] = "C-";
cr[8] = 1.66;
gr[9] = "D";
cr[9] = 1;
gr[10] = "F";
cr[10] = 0;
// retrieve user input
ingr[0] = document.GPACalcForm.GR1.value;
ingr[1] = document.GPACalcForm.GR2.value;
ingr[2] = document.GPACalcForm.GR3.value;
ingr[3] = document.GPACalcForm.GR4.value;
ingr[4] = document.GPACalcForm.GR5.value;
ingr[5] = document.GPACalcForm.GR6.value;
ingr[6] = document.GPACalcForm.GR7.value;
ingr[7] = document.GPACalcForm.GR8.value;
incr[0] = document.GPACalcForm.CR1.value;
incr[1] = document.GPACalcForm.CR2.value;
incr[2] = document.GPACalcForm.CR3.value;
incr[3] = document.GPACalcForm.CR4.value;
incr[4] = document.GPACalcForm.CR5.value;
incr[5] = document.GPACalcForm.CR6.value;
ingr[6] = document.GPACalcForm.GR7.value;
ingr[7] = document.GPACalcForm.GR8.value;

// Calculate GPA
var allgr =0;
var allcr = 0;
var gpa = 0;
for (var x = 0; x < 5 + 3; x++)
        {
        if (ingr[x] == "") break;
//      if (isNaN(parseInt(incr[x]))) alert("Error- You did not enter a numeric  credits value for Class If the class is worth 0 credits then enter the number 0 in  the field.");
        var validgrcheck = 0;
        for (var xx = 0; xx < grcount; xx++)
                {
                if (ingr[x] == gr[xx])
                        {
                        allgr = allgr + (parseInt(incr[x],10) * cr[xx]);
                        allcr = allcr + parseInt(incr[x],10);
                        validgrcheck = 1;
                        break;
                        }
                }
        if (validgrcheck == 0)
                {
                alert("Error- Could not recognize the grade entered for Class " + eval(x +  1) + ". Please use standard college grades in the form of A A- B+ ...F.");
                return 0;
                }
        }

// this if-check prevents a divide by zero error
if (allcr == 0)
        {
        alert("Error- You did not enter any credit values! GPA = N/A");
        return 0;
        }

gpa = allgr / allcr;

alert("GPA =  " + eval(gpa));

return 0;
}


//General Array Function
function MakeArray(n) {
   this.length = n;
   for (var i = 1; i <=n; i++) {
     this[i] = 0;
   }
}

//Initialize Days of Week Array
days = new MakeArray(7);
days[0] = "Saturday";
days[1] = "Sunday";
days[2] = "Monday";
days[3] = "Tuesday";
days[4] = "Wednesday";
days[5] = "Thursday";
days[6] = "Friday";

//Initialize Months Array
months = new MakeArray(12);
months[1] = "January";
months[2] = "February";
months[3] = "March";
months[4] = "April";
months[5] = "May";
months[6] = "June";
months[7] = "July";
months[8] = "August";
months[9] = "September";
months[10] = "October";
months[11] = "November";
months[12] = "December";

//Day of Week Function
function compute(form) {
   var val1 = parseInt(form.day.value, 10);
   if ((val1 < 0) || (val1 > 31)) {
      alert("Day is out of range");
   }
   var val2 = parseInt(form.month.value, 10);
   if ((val2 < 0) || (val2 > 12)) {
      alert("Month is out of range");
   }
   var val2x = parseInt(form.month.value, 10);
   var val3 = parseInt(form.year.value, 10);
   if (val3 < 1900) {
      alert("You're that old!");
   }
   if (val2 == 1) {
      val2x = 13;
      val3 = val3-1;
   }
   if (val2 == 2) {
      val2x = 14;
      val3 = val3-1;
   }
   var val4 = parseInt(((val2x+1)*3)/5, 10);
   var val5 = parseInt(val3/4, 10);
   var val6 = parseInt(val3/100, 10);
   var val7 = parseInt(val3/400, 10);
   var val8 = val1+(val2x*2)+val4+val3+val5-val6+val7+2;
   var val9 = parseInt(val8/7, 10);
   var val0 = val8-(val9*7);
   form.result1.value = months[val2]+" "+form.day.value +", "+form.year.value;
   form.result2.value = days[val0];
}

// end script -->

 /* Storing multi-line JSON string in a JS variable
using the new ES6 template literals */
var json = '{"book": {"name": "Harry Potter and the Goblet of Fire","author": "J. K. Rowling","year": 2000,"genre": "Fantasy Fiction","bestseller": true}}';

// Converting JSON object to JS object
var obj = JSON.parse(json);
console.log(obj);

// Defining custom functions
function firstFunction() {
	alert("The first function executed successfully!");
}

function secondFunction() {
	alert("The second function executed successfully");
}

// Selecting button element
var btn = document.getElementById("myBtn");

// Assigning event handlers to the button
btn.onclick = firstFunction;
btn.onclick = secondFunction; // This one overwrite the first

function quick_Sort(origArray) {
	if (origArray.length <= 1) {
		return origArray;
	} else {

		var left = [];
		var right = [];
		var newArray = [];
		var pivot = origArray.pop();
		var length = origArray.length;

		for (var i = 0; i < length; i++) {
			if (origArray[i] <= pivot) {
				left.push(origArray[i]);
			} else {
				right.push(origArray[i]);
			}
		}

		return newArray.concat(quick_Sort(left), pivot, quick_Sort(right));
	}
}

var myArray = [3, 0, 2, 5, -1, 4, 1 ];

console.log("Original array: " + myArray);
var sortedArray = quick_Sort(myArray);
console.log("Sorted array: " + sortedArray);

function merge_sort(left_part,right_part)
{
	var i = 0;
	var j = 0;
	var results = [];

	while (i < left_part.length || j < right_part.length) {
		if (i === left_part.length) {
			// j is the only index left_part
			results.push(right_part[j]);
			j++;
		}
      else if (j === right_part.length || left_part[i] <= right_part[j]) {
			results.push(left_part[i]);
			i++;
		} else {
			results.push(right_part[j]);
			j++;
		}
	}
	return results;
}

console.log(merge_sort([1,3,4], [3,7,9]));

var array_length;
/* to create MAX  array */
function heap_root(input, i) {
    var left = 2 * i + 1;
    var right = 2 * i + 2;
    var max = i;

    if (left < array_length && input[left] > input[max]) {
        max = left;
    }

    if (right < array_length && input[right] > input[max])     {
        max = right;
    }

    if (max != i) {
        swap(input, i, max);
        heap_root(input, max);
    }
}

function swap(input, index_A, index_B) {
    var temp = input[index_A];

    input[index_A] = input[index_B];
    input[index_B] = temp;
}

function heapSort(input) {

    array_length = input.length;

    for (var i = Math.floor(array_length / 2); i >= 0; i -= 1)      {
        heap_root(input, i);
      }

    for (i = input.length - 1; i > 0; i--) {
        swap(input, 0, i);
        array_length--;


        heap_root(input, 0);
    }
}

var arr = [3, 0, 2, 5, -1, 4, 1];
heapSort(arr);
console.log(arr);

function Selection_Sort(arr, compare_Function) {

  function compare(a, b) {
   return a - b;
   }
  var min = 0;
  var index = 0;
  var temp = 0;

 //{Function} compare_Function Compare function
  compare_Function = compare_Function || compare;

  for (var i = 0; i < arr.length; i += 1) {
    index = i;
    min = arr[i];

    for (var j = i + 1; j < arr.length; j += 1) {
      if (compare_Function(min, arr[j]) > 0) {
        min = arr[j];
        index = j;
      }
    }

    temp = arr[i];
    arr[i] = min;
    arr[index] = temp;
  }

  //return sorted arr
  return arr;
}

console.log(Selection_Sort([3, 0, 2, 5, -1, 4, 1], function(a, b) { return a - b; }));
console.log(Selection_Sort([3, 0, 2, 5, -1, 4, 1], function(a, b) { return b - a; }));


// https://code-projects.org/simple-tictactoe-in-javascript-with-source-code/
﻿// Player as Class
var countdown;
class Player {
    // Special constructor method
    constructor(name, score, turnTotal, avatar, spot) {
        // Set properties
        this.name = name;
        this.score = score;
        this.turnTotal = turnTotal;
        this.avatar = avatar;
        this.spot = spot;

    }
}

class Tiles {
    constructor(id, width, height, x, y, snake, ladder, next) {
        this.id = id;
        this.width = width;
        this.height = height;
        this.x = x;
        this.y = y;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
}

}


class Blocks {
    constructor(id, className, innerText, bgColor, snake, ladder, next) {
        this.id = id;
        this.className = className;
        this.innerText = innerText;
        this.bgColor = bgColor;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
    }

}



class MemoryBlock {
    constructor(id, frontImage, backImage) {
        this.id = id;
        this.blockCSS = "block";
        this.frontImage = frontImage;
        this.backImage = backImage;
        this.front = false;
        this.back = true;
        this.frontCSS = "block-front block-face";
        this.backCSS = "block-back block-face";
        this.imgCSS = "block-value";

    }
}

function startTimer(duration, display) {
    var timer = 60 * duration, minutes, seconds;
    countdown = setInterval(() => {
        minutes = parseInt(timer / 60, 10);
        seconds = parseInt(timer % 60, 10);
        minutes = minutes < 10 ? "0" + minutes : minutes;
        seconds = seconds < 10 ? "0" + seconds : seconds;
        display.textContent = `Time ${ minutes }:${ seconds }`;
        if (--timer < 0) {
            gameOver();
        }
    }, 1000);
}

class gameInfo {
    constructor(totalTime, cards) {
        this.cardsArray = cards;
        this.totalTime = totalTime;
        this.timeRemaining = totalTime;
      //  this.timer = document.getElementById('time-remaining');
        this.flips = 0;
    }
}

﻿var cells, emptyCells, moves, nextMove, avatar, gameOn, message, winSequence;
var cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7, cell8;

init();

function init() {
    moves = 0;
    gameOn = true;
    winSequence = [];

    cells = Array.from(document.getElementsByClassName('cell'));
    cell0 = document.getElementById("C0");
    cell1 = document.getElementById("C1");
    cell2 = document.getElementById("C2");
    cell3 = document.getElementById("C3");
    cell4 = document.getElementById("C4");
    cell5 = document.getElementById("C5");
    cell6 = document.getElementById("C6");
    cell7 = document.getElementById("C7");
    cell8 = document.getElementById("C8");
    document.getElementById("msg").textContent = "";
    for (var i = 0; i < cells.length; i++) {
        if (cells[i].hasChildNodes()){
            cells[i].removeChild(cells[i].childNodes[0]);
        }
        cells[i].style.backgroundColor = "";
    }
    addListeners();
}

function addListeners() {
    document.getElementById("btnReset").addEventListener("click", reset);
    emptyCells = cells.filter(element => element.innerHTML === "");
    for (var i = 0; i < emptyCells.length; i++) {
        emptyCells[i].addEventListener('click', clickCells);
    }
}
function removeListeners() {
    for (var i = 0; i < cells.length; i++) {
        cells[i].removeEventListener('click', clickCells);
    }
}

function reset() {
    // alert("in reset");
    init();
}


function clickCells() {
    takeTurn(this.id);
    if (checkWinner()) {
        var wait = ms => new Promise(resolve => setTimeout(resolve, ms));
        Promise.resolve(500).then(() => wait(500)).then(() => { nextPlayer(); });
    }
    else
        displayWinner();
}

function takeTurn(id) {
    if (moves <= 9) {
        moves += 1;
        var icon = "";
        if (moves % 2 !== 0) {
            icon = `<i class="fa fa-heart" style="font-size:50px;color:red"></i>`;
        }
        else {
            icon = `<i class="fa fa-music" style="font-size:50px;color:goldenrod"></i>`;
        }
        document.getElementById(id).innerHTML = icon;
        removeListeners();
    }

}

function nextPlayer() {
    emptyCells = cells.filter(element => element.innerHTML === "");
    if (emptyCells.length > 0) {
        var randomCell = emptyCells[Math.floor(Math.random() * emptyCells.length)];
        takeTurn(randomCell.id);
        if (checkWinner())
            addListeners();
        else
            displayWinner();
    }

}

function checkWinner() {


    if (cell0.hasChildNodes() && cell1.hasChildNodes() && cell2.hasChildNodes()) {
      //  console.log(cell0.childNodes[0].className);
        if (cell0.childNodes[0].className === cell1.childNodes[0].className && cell0.childNodes[0].className === cell2.childNodes[0].className) {
            message = cell0.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell0, cell1, cell2];
            gameOn = false;
        }
    }
    if (cell3.hasChildNodes() && cell4.hasChildNodes() && cell5.hasChildNodes()) {
      //  console.log(cell3.childNodes[0].className);
        if (cell3.childNodes[0].className === cell4.childNodes[0].className && cell3.childNodes[0].className === cell5.childNodes[0].className) {
            message = cell3.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell3, cell4, cell5];
            gameOn = false;
        }
    }
    if (cell6.hasChildNodes() && cell7.hasChildNodes() && cell8.hasChildNodes()) {
      //  console.log(cell6.childNodes[0].className);
        if (cell6.childNodes[0].className === cell7.childNodes[0].className && cell6.childNodes[0].className === cell8.childNodes[0].className) {
            message = cell6.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell6, cell7, cell8];
            gameOn = false;
        }
    }
    if (cell0.hasChildNodes() && cell3.hasChildNodes() && cell6.hasChildNodes()) {
        //console.log(cell0.childNodes[0].className);
        if (cell0.childNodes[0].className === cell3.childNodes[0].className && cell0.childNodes[0].className === cell6.childNodes[0].className) {
            message = cell0.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell0, cell3, cell6];
            gameOn = false;
        }
    }
    if (cell1.hasChildNodes() && cell4.hasChildNodes() && cell7.hasChildNodes()) {
        //console.log(cell1.childNodes[0].className);
        if (cell1.childNodes[0].className === cell4.childNodes[0].className && cell1.childNodes[0].className === cell7.childNodes[0].className) {
            message = cell1.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell1, cell4, cell7];
            gameOn = false;
        }
    }
    if (cell2.hasChildNodes() && cell5.hasChildNodes() && cell8.hasChildNodes()) {
       // console.log(cell2.childNodes[0].className);
        if (cell2.childNodes[0].className === cell5.childNodes[0].className && cell2.childNodes[0].className === cell8.childNodes[0].className) {
            message = cell2.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell2, cell5, cell8];
            gameOn = false;
        }
    }
    if (cell0.hasChildNodes() && cell4.hasChildNodes() && cell8.hasChildNodes()) {
       // console.log(cell0.childNodes[0].className);
        if (cell0.childNodes[0].className === cell4.childNodes[0].className && cell0.childNodes[0].className === cell8.childNodes[0].className) {
            message = cell0.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell0, cell4, cell8];
            gameOn = false;
        }
    }
    if (cell2.hasChildNodes() && cell4.hasChildNodes() && cell6.hasChildNodes()) {
       // console.log(cell2.childNodes[0].className);
        if (cell2.childNodes[0].className === cell4.childNodes[0].className && cell2.childNodes[0].className === cell6.childNodes[0].className) {
            message = cell2.childNodes[0].className === "fa fa-heart" ? "You are the winner!" : "AI is the winner!";
            winSequence = [cell2, cell4, cell6];
            gameOn = false;
        }
    }


        return gameOn;

}

function displayWinner() {
    document.getElementById("msg").textContent = message;
    for (var i = 0; i < winSequence.length; i++) {
        winSequence[i].style.backgroundColor = "cyan";
    }
}


// https://code-projects.org/pig-roll-in-javascript-with-source-code/

﻿// Player as Class
var countdown;
class Player {
    // Special constructor method
    constructor(name, score, turnTotal, avatar, spot) {
        // Set properties
        this.name = name;
        this.score = score;
        this.turnTotal = turnTotal;
        this.avatar = avatar;
        this.spot = spot;

    }
}

class Tiles {
    constructor(id, width, height, x, y, snake, ladder, next) {
        this.id = id;
        this.width = width;
        this.height = height;
        this.x = x;
        this.y = y;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
}

}


class Blocks {
    constructor(id, className, innerText, bgColor, snake, ladder, next) {
        this.id = id;
        this.className = className;
        this.innerText = innerText;
        this.bgColor = bgColor;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
    }

}



class MemoryBlock {
    constructor(id, frontImage, backImage) {
        this.id = id;
        this.blockCSS = "block";
        this.frontImage = frontImage;
        this.backImage = backImage;
        this.front = false;
        this.back = true;
        this.frontCSS = "block-front block-face";
        this.backCSS = "block-back block-face";
        this.imgCSS = "block-value";

    }
}

function startTimer(duration, display) {
    var timer = 60 * duration, minutes, seconds;
    countdown = setInterval(() => {
        minutes = parseInt(timer / 60, 10);
        seconds = parseInt(timer % 60, 10);
        minutes = minutes < 10 ? "0" + minutes : minutes;
        seconds = seconds < 10 ? "0" + seconds : seconds;
        display.textContent = `Time ${ minutes }:${ seconds }`;
        if (--timer < 0) {
            gameOver();
        }
    }, 1000);
}

class gameInfo {
    constructor(totalTime, cards) {
        this.cardsArray = cards;
        this.totalTime = totalTime;
        this.timeRemaining = totalTime;
      //  this.timer = document.getElementById('time-remaining');
        this.flips = 0;
    }
}


﻿/*
GAME RULES:
- The game has 2 players, playing in rounds
- In each turn, a player rolls a dice as many times as he whishes. Each result get added to his ROUND score
- BUT, if the player rolls a 1, all his ROUND score gets lost. After that, it's the next player's turn
- The player can choose to 'Hold', which means that his ROUND score gets added to his GLBAL score.
After that, it's the next player's turn
- The first player to reach 100 points on GLOBAL score wins the game
*/

var score, turnTotal, currentPlayer, gameOn, numText, countOfPlayers, players;

//Initialize the variables
init();

function rollDice() {
    if (gameOn) {
        var tempScore = parseInt(document.getElementById(`Score${currentPlayer}`).textContent);
        var tempTurnTotal = parseInt(document.getElementById(`turnTotal${currentPlayer}`).textContent);
        if (tempScore + tempTurnTotal < 20) {
            var ranDigit = Math.floor(Math.random() * 6) + 1;

            document.getElementById(`awsDice${currentPlayer}`).style.display = "block";
            document.getElementById(`awsDice${currentPlayer}`).className = `fas fa-dice-${numText[ranDigit - 1]}`;

            if (ranDigit !== 1) {
                //Add dice number to turntotal
                turnTotal += ranDigit;
                document.getElementById(`turnTotal${currentPlayer}`).textContent = turnTotal;
            } else {
                document.getElementById("message").textContent = "Oops! You rolled a One. Next Player's chance.";

                var wait = ms => new Promise(resolve => setTimeout(resolve, ms));
                Promise.resolve(3000).then(() => wait(1000)).then(() => { nextPlayer(); });

                //nextPlayer();
            }
        }
        else {
            passTurn();
        }

    }
}


function passTurn() {
    if (gameOn) {
        players[currentPlayer - 1].score += turnTotal;
        var latestScore = players[currentPlayer - 1].score;
        document.getElementById(`Score${currentPlayer}`).textContent = latestScore;
        if (latestScore >= 20) {
            document.getElementById("message").textContent = `We have a winner! Congratulations Player${currentPlayer}.`;
            document.getElementById(`P${currentPlayer}trophy`).style.display = "block";
            document.getElementById(`awsDice${currentPlayer}`).style.display = "none";
            gameOn = false;
        }
        else
            nextPlayer();
    }
}


function reset() {
   // alert("in reset");
    init();
}

function nextPlayer() {
    turnTotal = 0;
    document.getElementById("message").textContent = "";
    document.getElementById("turnTotal1").textContent = 0;
    document.getElementById("turnTotal2").textContent = 0;
    document.getElementById('awsDice1').style.display = "none";
    document.getElementById('awsDice2').style.display = "none";
    document.getElementById(`P${currentPlayer}active`).style.display = "none";
    currentPlayer = currentPlayer < countOfPlayers ? ++currentPlayer : 1;
    document.getElementById(`P${currentPlayer}active`).style.display = "block";
}

function init() {
    currentPlayer = 1;
    countOfPlayers = 2;
    players = new Array(countOfPlayers);
    gameOn = true;
    score = 0;
    turnTotal = 0;
    numText = ["one", "two", "three", "four", "five", "six"];
    for (var count = 0; count < countOfPlayers; count++) {
        var playerData = new Player(`Player${count + 1}`, score, turnTotal);
        players[count] = playerData;
    }
    document.getElementById('P1active').style.display = "block";
    document.getElementById('P2active').style.display = "none";
    document.getElementById('P1trophy').style.display = "none";
    document.getElementById('P2trophy').style.display = "none";
    document.getElementById("message").textContent = "";
    document.getElementById("turnTotal1").textContent = 0;
    document.getElementById("turnTotal2").textContent = 0;
    document.getElementById("Score1").textContent = 0;
    document.getElementById("Score2").textContent = 0;
    document.getElementById("btnRoll").addEventListener("click", rollDice);
    document.getElementById("btnPass").addEventListener("click", passTurn);
    document.getElementById("btnReset").addEventListener("click", reset);

}

// https://code-projects.org/flip-flop-game-in-javascript-with-source-code/
﻿// Player as Class
var countdown;
class Player {
    // Special constructor method
    constructor(name, score, turnTotal, avatar, spot) {
        // Set properties
        this.name = name;
        this.score = score;
        this.turnTotal = turnTotal;
        this.avatar = avatar;
        this.spot = spot;

    }
}

class Tiles {
    constructor(id, width, height, x, y, snake, ladder, next) {
        this.id = id;
        this.width = width;
        this.height = height;
        this.x = x;
        this.y = y;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
}

}


class Blocks {
    constructor(id, className, innerText, bgColor, snake, ladder, next) {
        this.id = id;
        this.className = className;
        this.innerText = innerText;
        this.bgColor = bgColor;
        this.snake = snake;
        this.ladder = ladder;
        this.next = next;
    }

}



class MemoryBlock {
    constructor(id, frontImage, backImage) {
        this.id = id;
        this.blockCSS = "block";
        this.frontImage = frontImage;
        this.backImage = backImage;
        this.front = false;
        this.back = true;
        this.frontCSS = "block-front block-face";
        this.backCSS = "block-back block-face";
        this.imgCSS = "block-value";

    }
}

function startTimer(duration, display) {
    var timer = 60 * duration, minutes, seconds;
    countdown = setInterval(() => {
        minutes = parseInt(timer / 60, 10);
        seconds = parseInt(timer % 60, 10);
        minutes = minutes < 10 ? "0" + minutes : minutes;
        seconds = seconds < 10 ? "0" + seconds : seconds;
        display.textContent = `Time ${ minutes }:${ seconds }`;
        if (--timer < 0) {
            gameOver();
        }
    }, 1000);
}

class gameInfo {
    constructor(totalTime, cards) {
        this.cardsArray = cards;
        this.totalTime = totalTime;
        this.timeRemaining = totalTime;
      //  this.timer = document.getElementById('time-remaining');
        this.flips = 0;
    }
}

﻿// for creating divs and shuffling blocks
var divblock, blockData, blockFrontImages, memoryBlockArr, blocksArray, blockFrontImagesAll, shuffledBlocks;
// for implementing flip n match logic
var currentlyFlippedArr, matchedCount, blockToMatch1, blockToMatch2;
// for implementing game info block
var flipCounter, timer, gameOn = false;

var overlays = Array.from(document.getElementsByClassName('overlay-text'));
overlays.forEach(overlay => {
    overlay.addEventListener('click', () => {
        overlay.classList.remove('visible');
        resetGame();
        init();

    });
});

function startCountdown() {
    return setInterval(() => {
        this.timeRemaining--;
        this.timer.innerText = this.timeRemaining;
        if (this.timeRemaining === 0)
            this.gameOver();
    }, 1000);
}

function resetGame() {
    var elements = document.getElementsByClassName("block");
        while (elements.length > 0) {
            elements[0].parentNode.removeChild(elements[0]);
        }
}

function init() {
    //initializing values
    gameOn = true;
     memoryBlockArr = new Array(18);
     blocksArray = [];
     blockFrontImagesAll = [];
     shuffledBlocks = [];
     currentlyFlippedArr = [];
     matchedCount = 0;
     flipCounter = 0;
     var minutes = 2;
     var display = document.getElementById("Timer");
     blockFrontImages = ["Images/pokemon1.gif",
        "Images/pokemon2.gif",
        "Images/pokemon3.gif",
        "Images/pokemon4.gif",
        "Images/pokemon5.gif",
        "Images/pokemon6.gif",
        "Images/pokemon7.gif",
        "Images/pokemon8.gif",
        "Images/pokemon9.gif"];
    // init();
    startTimer(minutes, display);
    blockFrontImagesAll = blockFrontImages.concat(blockFrontImages);
    shuffledBlocks = shuffleBlocks(blockFrontImagesAll);
    document.getElementById("Flips").innerText = `Flips: ${flipCounter}`;
    createElements();
}



function createElements() {
    var finalCount = shuffledBlocks.length;
    for (var i = 0; i < finalCount; i++) {
        var cardFront = shuffledBlocks.pop();
        blockData = new MemoryBlock(i, cardFront, "Images/pokemonBack.jpg");
        memoryBlockArr[i] = blockData;

        divblock = document.createElement("div");
        divblockFront = document.createElement("div");
        divblockBack = document.createElement("div");
        imgFront = document.createElement("img");
        imgBack = document.createElement("img");
        divblock.id = memoryBlockArr[i].id;
        divblock.className = memoryBlockArr[i].blockCSS;
        divblockFront.className = memoryBlockArr[i].frontCSS;
        divblockBack.className = memoryBlockArr[i].backCSS;
        imgFront.src = memoryBlockArr[i].frontImage;
        imgFront.className = memoryBlockArr[i].imgCSS;
        imgBack.src = memoryBlockArr[i].backImage;
        imgBack.className = memoryBlockArr[i].imgCSS;
        divblockFront.append(imgFront);
        divblockBack.append(imgBack);
        divblock.append(divblockFront);
        divblock.append(divblockBack);
        divblock.addEventListener('click', flipBlock);
        document.getElementById("gameMainBlock").append(divblock);
    }
}

function hideElements() {
    hideBlocks = Array.from(document.getElementsByClassName('block'));
    for (var i = 0; i < hideBlocks.length; i++) {
        document.getElementById(hideBlocks[i].id).classList.remove('visible');
    }
}

function shuffleBlocks(blocksArray) {
    var currentIndex = blocksArray.length, temporaryValue, randomIndex;
    // While there remain elements to shuffle...
    while (currentIndex !== 0) {
        // Pick an element from the remaining lot...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;
        // Swap it with the current element.
        temporaryValue = blocksArray[currentIndex];
        blocksArray[currentIndex] = blocksArray[randomIndex];
        blocksArray[randomIndex] = temporaryValue;
    }
    return blocksArray;
}

function flipBlock() {
    if (gameOn === true) {
        this.classList.add('visible');
        flipCounter += 1;
        document.getElementById("Flips").innerText = `Flips: ${flipCounter}`;


        if (blockToMatch1 !== this.id) {
            if (currentlyFlippedArr.length === 0) {
                currentlyFlippedArr.push(this.innerHTML);
                blockToMatch1 = this.id;
            }
            else if (currentlyFlippedArr.length === 1) {
                currentlyFlippedArr.push(this.innerHTML);
                blockToMatch2 = this.id;
                if (currentlyFlippedArr[0] === currentlyFlippedArr[1]) {
                    blocksMatched();
                }
                else {
                    gameOn = false;
                    var wait = ms => new Promise(resolve => setTimeout(resolve, ms));
                    Promise.resolve(800).then(() => wait(800)).then(() => { revertFlip(); });

                }
            }
        }
    }
}

function blocksMatched() {
    currentlyFlippedArr = [];
    matchedCount += 2;
    document.getElementById(blockToMatch1).removeEventListener('click', flipBlock);
    document.getElementById(blockToMatch2).removeEventListener('click', flipBlock);
    if (matchedCount === memoryBlockArr.length) {
       // if (matchedCount === 2) {
        var wait = ms => new Promise(resolve => setTimeout(resolve, ms));
        Promise.resolve(1000).then(() => wait(1000)).then(() => { showWin(); });
    }
}

function revertFlip() {
   // alert(blockToMatch1 + "  trying to revert  " + blockToMatch2);
    document.getElementById(blockToMatch1).classList.remove('visible');
    document.getElementById(blockToMatch2).classList.remove('visible');
    currentlyFlippedArr = [];
    gameOn = true;
}

function showWin() {
    hideElements();
    gameOn = false;
    document.getElementById('winText').classList.add('visible');
    clearInterval(countdown);
}

function gameOver() {
   // hideElements();
    gameOn = false;
    document.getElementById('gameOverText').classList.add('visible');
    clearInterval(countdown);
}

// https://www.webfx.com/blog/web-design/6-advanced-javascript-techniques-you-should-know/

function myObject() {
  this.property1 = "value1";
  this.property2 = "value2";
  var newValue = this.property1;
  this.performMethod = function() {
    myMethodValue = newValue;
    return myMethodValue;
  };
  }
  var myObjectInstance = new myObject();
  alert(myObjectInstance.performMethod());

function showStatistics(name, team, position, average, homeruns, rbi) {
  document.write("<p><strong>Name:</strong> " + arguments[0] + "<br />");
  document.write("<strong>Team:</strong> " + arguments[1] + "<br />");

  if (typeof arguments[2] === "string") {
    document.write("<strong>Position:</strong> " + position + "<br />");
  }
  if (typeof arguments[3] === "number") {
    document.write("<strong>Batting Average:</strong> " + average + "<br />");
  }
  if (typeof arguments[4] === "number") {
    document.write("<strong>Home Runs:</strong> " + homeruns + "<br />");
  }
  if (typeof arguments[5] === "number") {
    document.write("<strong>Runs Batted In:</strong> " + rbi + "</p>");
  }
}
showStatistics("Mark Teixeira");
showStatistics("Mark Teixeira", "New York Yankees");
showStatistics("Mark Teixeira", "New York Yankees", "1st Base", .284, 32, 101);

function showStatistics(args) {
  document.write("<p><strong>Name:</strong> " + args.name + "<br />");
  document.write("<strong>Team:</strong> " + args.team + "<br />");
  if (typeof args.position === "string") {
    document.write("<strong>Position:</strong> " + args.position + "<br />");
  }
  if (typeof args.average === "number") {
    document.write("<strong>Average:</strong> " + args.average + "<br />");
  }
  if (typeof args.homeruns === "number") {
    document.write("<strong>Home Runs:</strong> " + args.homeruns + "<br />");
  }
  if (typeof args.rbi === "number") {
    document.write("<strong>Runs Batted In:</strong> " + args.rbi + "</p>");
  }
}

showStatistics({
  name: "Mark Teixeira"
});

showStatistics({
  name: "Mark Teixeira",
  team: "New York Yankees"
});

showStatistics({
  name: "Mark Teixeira",
  team: "New York Yankees",
  position: "1st Base",
  average: .284,
  homeruns: 32,
  rbi: 101
});

var myLinkCollection = document.getElementsByTagName("a");

for (i=0;i<myLinkCollection.length;i++) {
  // do something with the anchor tags here
}

var myFooterElement = document.getElementById("footer");
var myLinksInFooter = myFooterElement.getElementsByTagName("a");
for (i=0;i<myLinksInFooter.length;i++) {
  // do something with footer anchor tags here
}

var myLinkCollection = document.getElementsByTagName("a");

for (i=0;i<myLinkCollection.length;i++) {
  if (myLinkCollection[i].parentNode.parentNode.id === "footer") {
    // do something with footer anchor tags here
  }
}

// end

var jsonTest = '{"test38":"value38","test472":"value472","test303":"value303","test298":"value298","test284":"value284","test608":"value608","test514":"value514","test543":"value543","test621":"value621","test437":"value437","test338":"value338","test610":"value610","test631":"value631","test292":"value292","test144":"value144","test146":"value146","test551":"value551","test497":"value497","test227":"value227","test602":"value602","test99":"value99","test132":"value132","test282":"value282","test95":"value95","test341":"value341","test115":"value115","test78":"value78","test535":"value535","test14":"value14","test320":"value320","test443":"value443","test66":"value66","test174":"value174","test489":"value489","test671":"value671","test72":"value72","test587":"value587","test321":"value321","test524":"value524","test134":"value134","test491":"value491","test18":"value18","test23":"value23","test193":"value193","test180":"value180","test256":"value256","test141":"value141","test529":"value529","test168":"value168","test368":"value368","test703":"value703","test650":"value650","test567":"value567","test411":"value411","test60":"value60","test591":"value591","test396":"value396","test399":"value399","test102":"value102","test585":"value585","test681":"value681","test314":"value314","test96":"value96","test40":"value40","test444":"value444","test435":"value435","test64":"value64","test594":"value594","test353":"value353","test616":"value616","test450":"value450","test29":"value29","test121":"value121","test718":"value718","test12":"value12","test432":"value432","test656":"value656","test171":"value171","test362":"value362","test505":"value505","test153":"value153","test663":"value663","test207":"value207","test184":"value184","test177":"value177","test152":"value152","test329":"value329","test36":"value36","test297":"value297","test434":"value434","test639":"value639","test151":"value151","test539":"value539","test557":"value557","test167":"value167","test704":"value704","test415":"value415","test307":"value307","test637":"value637","test605":"value605","test502":"value502","test237":"value237","test478":"value478","test448":"value448","test676":"value676","test652":"value652","test537":"value537","test147":"value147","test653":"value653","test381":"value381","test275":"value275","test216":"value216","test337":"value337","test186":"value186","test178":"value178","test612":"value612","test646":"value646","test707":"value707","test590":"value590","test94":"value94","test59":"value59","test603":"value603","test310":"value310","test382":"value382","test486":"value486","test356":"value356","test459":"value459","test278":"value278","test469":"value469","test172":"value172","test672":"value672","test359":"value359","test400":"value400","test195":"value195","test232":"value232","test25":"value25","test661":"value661","test267":"value267","test636":"value636","test209":"value209","test111":"value111","test33":"value33","test124":"value124","test65":"value65","test10":"value10","test693":"value693","test719":"value719","test155":"value155","test97":"value97","test98":"value98","test129":"value129","test228":"value228","test508":"value508","test609":"value609","test229":"value229","test570":"value570","test81":"value81","test597":"value597","test240":"value240","test471":"value471","test291":"value291","test604":"value604","test159":"value159","test683":"value683","test251":"value251","test386":"value386","test364":"value364","test416":"value416","test687":"value687","test49":"value49","test340":"value340","test246":"value246","test259":"value259","test473":"value473","test655":"value655","test406":"value406","test455":"value455","test662":"value662","test545":"value545","test420":"value420","test467":"value467","test374":"value374","test530":"value530","test513":"value513","test213":"value213","test475":"value475","test140":"value140","test568":"value568","test625":"value625","test695":"value695","test647":"value647","test77":"value77","test217":"value217","test56":"value56","test589":"value589","test311":"value311","test452":"value452","test104":"value104","test643":"value643","test439":"value439","test596":"value596","test288":"value288","test261":"value261","test573":"value573","test198":"value198","test373":"value373","test633":"value633","test699":"value699","test327":"value327","test369":"value369","test501":"value501","test351":"value351","test419":"value419","test424":"value424","test107":"value107","test231":"value231","test666":"value666","test70":"value70","test266":"value266","test383":"value383","test487":"value487","test326":"value326","test674":"value674","test583":"value583","test531":"value531","test82":"value82","test39":"value39","test632":"value632","test630":"value630","test163":"value163","test403":"value403","test355":"value355","test393":"value393","test103":"value103","test112":"value112","test528":"value528","test295":"value295","test28":"value28","test556":"value556","test162":"value162","test357":"value357","test413":"value413","test569":"value569","test462":"value462","test645":"value645","test343":"value343","test179":"value179","test281":"value281","test225":"value225","test593":"value593","test7":"value7","test105":"value105","test192":"value192","test92":"value92","test346":"value346","test158":"value158","test88":"value88","test219":"value219","test571":"value571","test1":"value1","test272":"value272","test130":"value130","test613":"value613","test238":"value238","test258":"value258","test309":"value309","test323":"value323","test348":"value348","test322":"value322","test638":"value638","test335":"value335","test182":"value182","test538":"value538","test517":"value517","test410":"value410","test93":"value93","test506":"value506","test380":"value380","test688":"value688","test127":"value127","test336":"value336","test183":"value183","test6":"value6","test317":"value317","test401":"value401","test720":"value720","test100":"value100","test592":"value592","test377":"value377","test106":"value106","test352":"value352","test138":"value138","test723":"value723","test696":"value696","test22":"value22","test402":"value402","test79":"value79","test117":"value117","test431":"value431","test580":"value580","test425":"value425","test330":"value330","test412":"value412","test114":"value114","test331":"value331","test521":"value521","test461":"value461","test205":"value205","test148":"value148","test453":"value453","test55":"value55","test560":"value560","test222":"value222","test187":"value187","test358":"value358","test86":"value86","test390":"value390","test286":"value286","test492":"value492","test46":"value46","test427":"value427","test277":"value277","test397":"value397","test214":"value214","test63":"value63","test294":"value294","test189":"value189","test527":"value527","test318":"value318","test16":"value16","test58":"value58","test598":"value598","test304":"value304","test108":"value108","test482":"value482","test644":"value644","test512":"value512","test154":"value154","test236":"value236","test271":"value271","test408":"value408","test476":"value476","test480":"value480","test582":"value582","test628":"value628","test137":"value137","test156":"value156","test544":"value544","test546":"value546","test239":"value239","test210":"value210","test463":"value463","test125":"value125","test711":"value711","test552":"value552","test218":"value218","test441":"value441","test301":"value301","test675":"value675","test481":"value481","test166":"value166","test648":"value648","test689":"value689","test555":"value555","test194":"value194","test175":"value175","test224":"value224","test474":"value474","test387":"value387","test24":"value24","test73":"value73","test511":"value511","test332":"value332","test35":"value35","test522":"value522","test532":"value532","test136":"value136","test248":"value248","test553":"value553","test685":"value685","test700":"value700","test627":"value627","test417":"value417","test442":"value442","test150":"value150","test466":"value466","test640":"value640","test724":"value724","test599":"value599","test274":"value274","test328":"value328","test173":"value173","test226":"value226","test71":"value71","test421":"value421","test113":"value113","test701":"value701","test376":"value376","test470":"value470","test110":"value110","test268":"value268","test488":"value488","test697":"value697","test423":"value423","test370":"value370","test710":"value710","test622":"value622","test574":"value574","test221":"value221","test283":"value283","test588":"value588","test87":"value87","test623":"value623","test75":"value75","test312":"value312","test233":"value233","test26":"value26","test27":"value27","test673":"value673","test62":"value62","test50":"value50","test202":"value202","test581":"value581","test493":"value493","test313":"value313","test438":"value438","test709":"value709","test629":"value629","test61":"value61","test624":"value624","test705":"value705","test654":"value654","test350":"value350","test686":"value686","test120":"value120","test149":"value149","test257":"value257","test678":"value678","test44":"value44","test135":"value135","test143":"value143","test477":"value477","test600":"value600","test516":"value516","test500":"value500","test145":"value145","test197":"value197","test123":"value123","test235":"value235","test460":"value460","test716":"value716","test651":"value651","test698":"value698","test392":"value392","test116":"value116","test394":"value394","test201":"value201","test118":"value118","test191":"value191","test230":"value230","test91":"value91","test223":"value223","test45":"value45","test523":"value523","test32":"value32","test21":"value21","test499":"value499","test349":"value349","test164":"value164","test440":"value440","test8":"value8","test677":"value677","test285":"value285","test133":"value133","test542":"value542","test446":"value446","test342":"value342","test595":"value595","test422":"value422","test660":"value660","test190":"value190","test409":"value409","test617":"value617","test43":"value43","test405":"value405","test215":"value215","test308":"value308","test659":"value659","test414":"value414","test388":"value388","test211":"value211","test548":"value548","test176":"value176","test85":"value85","test641":"value641","test536":"value536","test611":"value611","test679":"value679","test465":"value465","test0":"value0","test484":"value484","test245":"value245","test563":"value563","test398":"value398","test540":"value540","test680":"value680","test634":"value634","test504":"value504","test691":"value691","test584":"value584","test692":"value692","test668":"value668","test495":"value495","test199":"value199","test550":"value550","test42":"value42","test279":"value279","test119":"value119","test334":"value334","test534":"value534","test576":"value576","test371":"value371","test34":"value34","test667":"value667","test713":"value713","test203":"value203","test139":"value139","test169":"value169","test525":"value525","test345":"value345","test509":"value509","test706":"value706","test619":"value619","test684":"value684","test429":"value429","test142":"value142","test53":"value53","test572":"value572","test241":"value241","test315":"value315","test255":"value255","test160":"value160","test715":"value715","test263":"value263","test76":"value76","test253":"value253","test451":"value451","test526":"value526","test658":"value658","test562":"value562","test165":"value165","test717":"value717","test30":"value30","test554":"value554","test479":"value479","test319":"value319","test606":"value606","test367":"value367","test454":"value454","test391":"value391","test566":"value566","test722":"value722","test620":"value620","test90":"value90","test68":"value68","test276":"value276","test54":"value54","test324":"value324","test389":"value389","test565":"value565","test494":"value494","test280":"value280","test265":"value265","test694":"value694","test670":"value670","test3":"value3","test533":"value533","test200":"value200","test690":"value690","test299":"value299","test333":"value333","test708":"value708","test669":"value669","test206":"value206","test507":"value507","test293":"value293","test561":"value561","test635":"value635","test657":"value657","test250":"value250","test404":"value404","test41":"value41","test57":"value57","test48":"value48","test366":"value366","test244":"value244","test375":"value375","test483":"value483","test575":"value575","test52":"value52","test47":"value47","test549":"value549","test558":"value558","test15":"value15","test458":"value458","test464":"value464","test188":"value188","test515":"value515","test208":"value208","test498":"value498","test122":"value122","test449":"value449","test11":"value11","test339":"value339","test418":"value418","test128":"value128","test379":"value379","test586":"value586","test642":"value642","test270":"value270","test541":"value541","test559":"value559","test665":"value665","test262":"value262","test31":"value31","test181":"value181","test428":"value428","test503":"value503","test365":"value365","test520":"value520","test712":"value712","test4":"value4","test316":"value316","test601":"value601","test74":"value74","test436":"value436","test2":"value2","test252":"value252","test496":"value496","test490":"value490","test234":"value234","test204":"value204","test51":"value51","test468":"value468","test269":"value269","test384":"value384","test664":"value664","test360":"value360","test378":"value378","test37":"value37","test447":"value447","test564":"value564","test607":"value607","test247":"value247","test305":"value305","test80":"value80","test618":"value618","test395":"value395","test89":"value89","test430":"value430","test264":"value264","test682":"value682","test347":"value347","test9":"value9","test273":"value273","test325":"value325","test361":"value361","test296":"value296","test19":"value19","test84":"value84","test260":"value260","test13":"value13","test407":"value407","test300":"value300","test426":"value426","test626":"value626","test17":"value17","test243":"value243","test242":"value242","test714":"value714","test578":"value578","test109":"value109","test67":"value67","test354":"value354","test287":"value287","test83":"value83","test5":"value5","test702":"value702","test249":"value249","test485":"value485","test518":"value518","test220":"value220","test161":"value161","test519":"value519","test579":"value579","test126":"value126","test302":"value302","test254":"value254","test433":"value433","test649":"value649","test577":"value577","test212":"value212","test289":"value289","test344":"value344","test445":"value445","test157":"value157","test614":"value614","test363":"value363","test372":"value372","test290":"value290","test196":"value196","test170":"value170","test385":"value385","test131":"value131","test457":"value457","test20":"value20","test69":"value69","test510":"value510","test615":"value615","test547":"value547","test306":"value306","test101":"value101","test456":"value456","test721":"value721","test185":"value185"}';
