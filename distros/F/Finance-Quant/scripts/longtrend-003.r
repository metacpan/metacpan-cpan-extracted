## cf with tseries:::get.hist.quote() and its::priceIts()
date <- function() {
t <- Sys.time();
y <- substring(as.Date(t, "%d%B%Y"),0,4);
d <- substring(t,9,10);
sub<-substring(months(t),0,3)
day<-substring(weekdays(t),0,3)
gmt <-as.POSIXlt(t, "GMT")
paste(y,sub,d, sep = "-")
}




folder <- date()


file<- sprintf("/tmp/Finance-Quant/%s/backtest/longtrend_backtest_AAPL.pdf",folder)

file

pdf(file)




require(quantmod)
require(TTR)
require(blotter)



# Try to clean up in case the demo was run previously
try(rm("account.longtrend","portfolio.longtrend",pos=.blotter),silent=TRUE)
try(rm("ltaccount","ltportfolio","ClosePrice","CurrentDate","equity","AAPL","i","initDate","initEq","Posn","UnitSize","verbose"),silent=TRUE)


# Set initial values
initDate='1997-12-31'
initEq=10000

# Load data with quantmod
print("Loading data")
currency("USD")
stock("AAPL",currency="USD",multiplier=1)
getSymbols('AAPL', src='yahoo', index.class=c("POSIXt","POSIXct"),from='2011-04-01')
#AAPL=to(AAPL, indexAt='endof')

# Set up indicators with TTR
print("Setting up indicators")
AAPL$SMA10m <- SMA(AAPL[,grep('Adj',colnames(AAPL))], 20)

# Set up a portfolio object and an account object in blotter
print("Initializing portfolio and account structure")
ltportfolio='longtrend'
ltaccount='longtrend'

initPortf(ltportfolio,'AAPL', initDate=initDate)
initAcct(ltaccount,portfolios='longtrend', initDate=initDate, initEq=initEq)
verbose=TRUE

# Create trades
for( i in 20:NROW(AAPL) ) { 
# browser()
CurrentDate=time(AAPL)[i]
cat(".")
equity = getEndEq(ltaccount, CurrentDate)

ClosePrice = as.numeric(Ad(AAPL[i,]))
Posn = getPosQty(ltportfolio, Symbol='AAPL', Date=CurrentDate)
UnitSize = as.numeric(trunc(equity/ClosePrice))

# Position Entry (assume fill at close)
if( Posn == 0 ) { 
# No position, so test to initiate Long position
if( as.numeric(Ad(AAPL[i,])) > as.numeric(AAPL[i,'SMA10m']) ) { 
cat('\n')
# Store trade with blotter
addTxn(ltportfolio, Symbol='AAPL', TxnDate=CurrentDate, TxnPrice=ClosePrice, TxnQty = UnitSize , TxnFees=0, verbose=verbose)
} 
} else {
# Have a position, so check exit
if( as.numeric(Ad(AAPL[i,]))  <  as.numeric(AAPL[i,'SMA10m'])) { 
cat('\n')
# Store trade with blotter
addTxn(ltportfolio, Symbol='AAPL', TxnDate=CurrentDate, TxnPrice=ClosePrice, TxnQty = -Posn , TxnFees=0, verbose=verbose)
} 
}

# Calculate P&L and resulting equity with blotter
updatePortf(ltportfolio, Dates = CurrentDate)
updateAcct(ltaccount, Dates = CurrentDate)
updateEndEq(ltaccount, Dates = CurrentDate)
} # End dates loop
cat('\n')

# Chart results with quantmod
chart.Posn(ltportfolio, Symbol = 'AAPL', Dates = '1998::')
plot(add_SMA(n=10,col='darkgreen', on=1))

#look at a transaction summary
getTxns(Portfolio="longtrend", Symbol="AAPL")

# Copy the results into the local environment
print("Retrieving resulting portfolio and account")
ltportfolio = getPortfolio("longtrend")
ltaccount = getAccount("longtrend")
x <- ltportfolio
y <- ltaccount

x
#y
dev.off()

