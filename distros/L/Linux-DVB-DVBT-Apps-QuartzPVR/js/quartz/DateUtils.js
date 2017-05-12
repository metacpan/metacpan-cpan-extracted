/*
Date utilities

*/
// Make sure we haven't already been loaded
var DateUtils;
if (DateUtils && (typeof DateUtils != "object" || DateUtils.NAME))
    throw new Error("Namespace 'DateUtils' already exists");

// Create our namespace, and specify some meta-information
DateUtils = {};
DateUtils.NAME = "DateUtils";    // The name of this namespace
DateUtils.VERSION = 1.0;    // The version of this namespace

DateUtils.DAY_NAMES = [
	'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
] ;

DateUtils.MONTH_NAMES = [
	'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
	'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
] ;

DateUtils.DAY_SUFFIX = [
	'', 
//	1	  2		3	  4		5	   6	7	   8	9	  10
	'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 
//	11	  12	13	  14	15	   16	17	   18	19	  20
	'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 
//	21	  22	23	  24	25	   26	27	  28	29	  30
	'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 
//	31	  
	'st' 
] ;


DateUtils.date_regexp = /(\d+)\-(\d+)\-(\d+)/ ;
DateUtils.time_regexp = /(\d+):(\d+)/ ;

/*------------------------------------------------------------------------------------------------------*/
// Convert time string HH:MM to mins
DateUtils.time2mins = function(timestr) 
{
	return parseInt(timestr.substring(0, 2), 10) * 60 + parseInt(timestr.substring(3, 5), 10) ;
}

/*------------------------------------------------------------------------------------------------------*/
// Convert date & time into minutes
DateUtils.datetime2mins = function(date, time) 
{
	var date = DateUtils.datetime2date(date, time) ;
	var millisecs = date.valueOf() ; 
	return parseInt(millisecs / 60000, 10) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Convert date & time into a Date
//Date in YYYY-mm-dd, time in HH:MM
DateUtils.datetime2date = function(date, time) 
{
	
	var date_result = date.match(DateUtils.date_regexp) ;
	var time_result = time.match(DateUtils.time_regexp) ;
	
	var date ;
	if ((date_result != null) && (time_result != null))
	{
		var yy = parseInt(date_result[1], 10) ;
		var mm = parseInt(date_result[2], 10) ;	// force base 10 because we have a leading zero 
		var dd = parseInt(date_result[3], 10) ;
		var h = parseInt(time_result[1], 10) ;
		var m = parseInt(time_result[2], 10) ;

		date = new Date(yy, mm-1, dd, h, m, 0) ;
	}
	
	return date ;
}

/*------------------------------------------------------------------------------------------------------*/
//Convert date string into a Date object
//Date in YYYY-mm-dd, time in HH:MM
DateUtils.date2dt = function(date) 
{
	var dt = DateUtils.datetime2date(date, "00:00") ;
	return dt ;
}

/*------------------------------------------------------------------------------------------------------*/
// Get day name from date object  
DateUtils.dayname = function(dt) 
{
//var day = dt.getDay() ;
//var dayname = DateUtils.DAY_NAMES[day] ;

	return DateUtils.DAY_NAMES[dt.getDay()] ;
}

/*------------------------------------------------------------------------------------------------------*/
// Get month name from date object  
DateUtils.monthname = function(dt) 
{
	return DateUtils.MONTH_NAMES[dt.getMonth()] ;
}

/*------------------------------------------------------------------------------------------------------*/
// Convert date object into string YYYY-M-D  
DateUtils.date = function(dt) 
{
	return dt.getFullYear() + "-" + (dt.getMonth()+1) + "-" + dt.getDate() ;
}

/*------------------------------------------------------------------------------------------------------*/
//Get day suffix (st, nd etc) from day  
DateUtils.day2suffix = function(day) 
{
	return DateUtils.DAY_SUFFIX[day] ;
}

/*------------------------------------------------------------------------------------------------------*/
//Get day suffix (st, nd etc) from Date object  
DateUtils.dt2suffix = function(dt) 
{
	return DateUtils.day2suffix(dt.getDate()) ;
}

/*------------------------------------------------------------------------------------------------------*/
//Convert a Date object into a string of the format: "Wed 21st Sep"
DateUtils.dt2string = function(dt) 
{
	var dayname = DateUtils.dayname(dt) ;
	var day = dt.getDate() ;
	var suffix = DateUtils.day2suffix(day) ;
	var monthname = DateUtils.monthname(dt) ;
	
	var string = dayname + " " + day + suffix + " " + monthname ;
	
	return string ;
}

/*------------------------------------------------------------------------------------------------------*/
//Convert a Date object into a time string of the format: "HH:MM"
DateUtils.dt2hm = function(dt) 
{
	var hours = dt.getHours() ;
	var minutes = dt.getMinutes() ;

	var string = "" ;

	if (hours < 10) string += "0" ;
	string += hours ;
	
	string += ":" ;
	if (minutes < 10) string += "0" ;
	string += minutes ;
	
	return string ;
}

/*------------------------------------------------------------------------------------------------------*/
//Convert a Date object into a time string of the format: "HH:MM:SS"
DateUtils.dt2hms = function(dt) 
{
	var string = DateUtils.dt2hm(dt) ;
	
	var seconds = dt.getSeconds() ;
	
	string += ":" ;
	if (seconds < 10) string += "0" ;
	string += seconds ;
	
	return string ;
}

/*------------------------------------------------------------------------------------------------------*/
// Convert date string into integer
DateUtils.date2int = function(date) 
{
	var dateInt = 0 ;
	var result = date.split("-") ;
	if (result.length == 3)
	{
		dateInt = parseInt(result[0] + result[1] + result[2], 10) ;
	}
	return dateInt ;
}

/*------------------------------------------------------------------------------------------------------*/
// Compare 2 date strings
DateUtils.dateCompare = function(a_date, b_date) 
{
	var a_int = DateUtils.date2int(a_date) ;
	var b_int = DateUtils.date2int(b_date) ;
	
	return a_int - b_int ;
}

