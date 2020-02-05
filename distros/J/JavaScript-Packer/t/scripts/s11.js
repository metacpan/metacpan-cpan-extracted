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
  document.getElementById(‘banner’).src=’large_img.gif’;
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
var sent = "This is a demonstration of a banner moving from the left to right. It makes use of the substring property of Javascript to make an interesting display"
var slen = sent.length
var siz = 25
var a = -3, b = 0
var subsent = "x"

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
b = a + siz
makeSub(a,b);
return subsent
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

﻿//investment evaluation section
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
var snowmax=35

// Set the colors for the snow. Add as many colors as you like
var snowcolor=new Array("#aaaacc","#ddddFF","#ccccDD")

// Set the fonts, that create the snowflakes. Add as many fonts as you like
var snowtype=new Array("Arial Black","Arial Narrow","Times","Comic Sans MS")

// Set the letter that creates your snowflake (recommended:*)
var snowletter="*"

// Set the speed of sinking (recommended values range from 0.3 to 2)
var sinkspeed=0.6

// Set the maximal-size of your snowflaxes
var snowmaxsize=22

// Set the minimal-size of your snowflaxes
var snowminsize=8

// Set the snowing-zone
// Set 1 for all-over-snowing, set 2 for left-side-snowing
// Set 3 for center-snowing, set 4 for right-side-snowing
var snowingzone=3

///////////////////////////////////////////////////////////////////////////
// CONFIGURATION ENDS HERE
///////////////////////////////////////////////////////////////////////////


// Do not edit below this line
var snow=new Array()
var marginbottom
var marginright
var timer
var i_snow=0
var x_mv=new Array();
var crds=new Array();
var lftrght=new Array();
var browserinfos=navigator.userAgent
var ie5=document.all&&document.getElementById&&!browserinfos.match(/Opera/)
var ns6=document.getElementById&&!document.all
var opera=browserinfos.match(/Opera/)
var browserok=ie5||ns6||opera

function randommaker(range) {
	rand=Math.floor(range*Math.random())
    return rand
}

function initsnow() {
	if (ie5 || opera) {
		marginbottom = document.body.clientHeight
		marginright = document.body.clientWidth
	}
	else if (ns6) {
		marginbottom = window.innerHeight
		marginright = window.innerWidth
	}
	var snowsizerange=snowmaxsize-snowminsize
	for (i=0;i<=snowmax;i++) {
		crds[i] = 0;
    	lftrght[i] = Math.random()*15;
    	x_mv[i] = 0.03 + Math.random()/10;
		snow[i]=document.getElementById("s"+i)
		snow[i].style.fontFamily=snowtype[randommaker(snowtype.length)]
		snow[i].size=randommaker(snowsizerange)+snowminsize
		snow[i].style.fontSize=snow[i].size
		snow[i].style.color=snowcolor[randommaker(snowcolor.length)]
		snow[i].sink=sinkspeed*snow[i].size/5
		if (snowingzone==1) {snow[i].posx=randommaker(marginright-snow[i].size)}
		if (snowingzone==2) {snow[i].posx=randommaker(marginright/2-snow[i].size)}
		if (snowingzone==3) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/4}
		if (snowingzone==4) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/2}
		snow[i].posy=randommaker(2*marginbottom-marginbottom-2*snow[i].size)
		snow[i].style.left=snow[i].posx
		snow[i].style.top=snow[i].posy
	}
	movesnow()
}

function movesnow() {
	for (i=0;i<=snowmax;i++) {
		crds[i] += x_mv[i];
		snow[i].posy+=snow[i].sink
		snow[i].style.left=snow[i].posx+lftrght[i]*Math.sin(crds[i]);
		snow[i].style.top=snow[i].posy

		if (snow[i].posy>=marginbottom-2*snow[i].size || parseInt(snow[i].style.left)>(marginright-3*lftrght[i])){
			if (snowingzone==1) {snow[i].posx=randommaker(marginright-snow[i].size)}
			if (snowingzone==2) {snow[i].posx=randommaker(marginright/2-snow[i].size)}
			if (snowingzone==3) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/4}
			if (snowingzone==4) {snow[i].posx=randommaker(marginright/2-snow[i].size)+marginright/2}
			snow[i].posy=0
		}
	}
	var timer=setTimeout("movesnow()",50)
}

for (i=0;i<=snowmax;i++) {
	document.write("<span id='s"+i+"' style='position:absolute;top:-"+snowmaxsize+"'>"+snowletter+"</span>")
}
if (browserok) {
	window.onload=initsnow
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
var gValue = 1
var kgValue = 1000
var ounceValue = 28.3495
var lbValue = 453.592
var tValue = 907184
function toCM()
{
var i = document.convert.unit.selectedIndex
var thisUnit = document.convert.unit.options[i].value
if (thisUnit == "G")
        {
document.convert.g.value = document.convert.InUnit.value
        }
else if(thisUnit == "KG")
        {
document.convert.g.value = document.convert.InUnit.value * kgValue
        }
else if(thisUnit == "OUNCE" )
        {
document.convert.g.value = document.convert.InUnit.value * ounceValue
        }
else if(thisUnit == "LB" )
        {
document.convert.g.value = document.convert.InUnit.value * lbValue
        }
else if(thisUnit == "T" )
        {
document.convert.g.value = document.convert.InUnit.value * tValue
        }
toAll()
}
function toAll()
{
var m = document.convert.g.value
document.convert.kg.value = m / kgValue
document.convert.ounce.value = m / ounceValue
document.convert.lb.value = m / lbValue
document.convert.t.value = m / tValue
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
                amount = amount + ".00"
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

<!-- Original:  Sandeep V. Tamhankar (stamhankar@hotmail.com) -->

<!-- This script and many more are available free online at -->
<!-- The JavaScript Source!! http://javascript.internet.com -->

<!-- Begin
function isValidDate(dateStr) {
// Checks for the following valid date formats:
// MM/DD/YY   MM/DD/YYYY   MM-DD-YY   MM-DD-YYYY
// Also separates date into month, day, and year variables

var datePat = /^(\d{1,2})(\/|-)(\d{1,2})\2(\d{2}|\d{4})$/;

// To require a 4 digit year entry, use this line instead:
// var datePat = /^(\d{1,2})(\/|-)(\d{1,2})\2(\d{4})$/;

var matchArray = dateStr.match(datePat); // is the format ok?
if (matchArray == null) {
alert("Date is not in a valid format.")
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
alert("Month "+month+" doesn't have 31 days!")
return false
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
  sym.innerHTML=table
 sh.innerHTML=""
}
function show() {
 sh.innerHTML=alphaArray[ax]
 sym.innerHTML="<center>Guess? :) <a href=\"javascript:viewtable()\">Repeat</a></center>";
}

<!-- Original:  Tim Wallace



<!-- Begin
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
var face0=new Image()
face0.src="d1.gif"
var face1=new Image()
face1.src="d2.gif"
var face2=new Image()
face2.src="d3.gif"
var face3=new Image()
face3.src="d4.gif"
var face4=new Image()
face4.src="d5.gif"
var face5=new Image()
face5.src="d6.gif"

function throwdice(){
//create a random integer between 0 and 5
var randomdice=Math.round(Math.random()*5)
document.images["mydice"].src=eval("face"+randomdice+".src")
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

<!-- begin script

//General Array Function
function MakeArray(n) {
   this.length = n;
   for (var i = 1; i <=n; i++) {
     this[i] = 0;
   }
}

//Initialize Days of Week Array
days = new MakeArray(7);
days[0] = "Saturday"
days[1] = "Sunday"
days[2] = "Monday"
days[3] = "Tuesday"
days[4] = "Wednesday"
days[5] = "Thursday"
days[6] = "Friday"

//Initialize Months Array
months = new MakeArray(12);
months[1] = "January"
months[2] = "February"
months[3] = "March"
months[4] = "April"
months[5] = "May"
months[6] = "June"
months[7] = "July"
months[8] = "August"
months[9] = "September"
months[10] = "October"
months[11] = "November"
months[12] = "December"

//Day of Week Function
function compute(form) {
   var val1 = parseInt(form.day.value, 10)
   if ((val1 < 0) || (val1 > 31)) {
      alert("Day is out of range")
   }
   var val2 = parseInt(form.month.value, 10)
   if ((val2 < 0) || (val2 > 12)) {
      alert("Month is out of range")
   }
   var val2x = parseInt(form.month.value, 10)
   var val3 = parseInt(form.year.value, 10)
   if (val3 < 1900) {
      alert("You're that old!")
   }
   if (val2 == 1) {
      val2x = 13;
      val3 = val3-1
   }
   if (val2 == 2) {
      val2x = 14;
      val3 = val3-1
   }
   var val4 = parseInt(((val2x+1)*3)/5, 10)
   var val5 = parseInt(val3/4, 10)
   var val6 = parseInt(val3/100, 10)
   var val7 = parseInt(val3/400, 10)
   var val8 = val1+(val2x*2)+val4+val3+val5-val6+val7+2
   var val9 = parseInt(val8/7, 10)
   var val0 = val8-(val9*7)
   form.result1.value = months[val2]+" "+form.day.value +", "+form.year.value
   form.result2.value = days[val0]
}

// end script -->