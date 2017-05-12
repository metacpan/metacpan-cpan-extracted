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

file<- sprintf("/tmp/Finance-Quant/%s%s",folder,"/charts/chart_AAPL.pdf")

file

pdf(file)



require(quantmod)

## $Id: bollingerBands.R,v 1.3 2005/07/24 17:04:20 edd Exp $

## cf with tseries:::get.hist.quote() and its::priceIts()
getData <- function(instrument = "AAPL",
                    start=format(Sys.time()-60*60*24*252,
                      "%Y-%m-%d"),      ## 200 days ago
                    end=format(Sys.time(), "%Y-%m-%d"), 	## today
                    quote = c("Open","High", "Low", "Close", "Volume"),
                    method = "auto",
                    origin = "1899-12-30",
                    compression="d",
                    quiet=TRUE) {
  start <- as.POSIXct(start,tz="GMT")   # store date as POSIXct
  end <- as.POSIXct(end,tz="GMT")
  url <-                                # form URL for download
    paste("http://chart.yahoo.com/table.csv?s=",
          instrument,
          format(start,
                 paste("&a=",as.character(as.numeric(format(start, "%m")) - 1),
                       "&b=%d&c=%Y", sep = "")),
          format(end,
                 paste("&d=", as.character(as.numeric(format(end, "%m")) - 1),
                       "&e=%d&f=%Y", sep = "")),
          "&g=", compression,
          "&q=q&y=0&z=", instrument, "&x=.csv", sep = "")
  destfile <- tempfile()                # and download to tempfile
  status <- download.file(url, destfile, method = method, quiet=quiet)
  if (status != 0) {
    #unlink(destfile)
    stop(paste("download error, status", status))
  }
  nlines <- length(count.fields(destfile, sep = "\n"))
  if (nlines == 1) {
   # unlink(destfile)
    stop(paste("No data available for", instrument))
  }
  v <- readLines(destfile)
  cl <- grep("^<!",v)                   # look for html comments
  if (length(cl))
    v <- v[-cl]                         # and invert the grep
  data <- read.csv(textConnection(v))   # load all that do not match           
  data <- data[nrow(data):1,]           # and inverse order in data

  rownames(data) <- data[,"Date"]       # re-store dates as rownames
  data <- data[, quote, drop=FALSE]     # and drop unwanted columns

  #unlink(destfile)
  return(data)
}

## compute Bollinger Bands on price and scaled volume
computeBollingerBands <- function(dat, ndays=20, nsd=2, nvol=50) {

  ## create a (normalised, but that's just candy) weight vector
  weights <- rep(1/ndays, ndays)
  ## and apply it as a one-sided moving average calculations, see help(filter)
  bbmiddle <- as.vector(filter(dat$Close, weights,
                               method="convolution", side=1))
  ## use var(x) = E(x^2) - E(x)^2 to compute rolling variances
  v <- filter(dat$Close^2, weights, method="convolution", side=1) - bbmiddle^2
  ## from which we calculate rolling standard deviations the usual way
  bbsd <- as.vector(sqrt(v))

  bbupper <- bbmiddle + nsd*bbsd        # upper Bollinger band
  bblower <- bbmiddle - nsd*bbsd        # lowet Bollinger band

  ## create a (normalised, but that's just candy) weight vector for avg.vol.
  weights <- rep(1/nvol, nvol)
  ## and apply it as a one-sided moving average calculations, see help(filter)
  avgvol <- as.vector(filter(dat$Volume, weights,method="convolution", side=1))
  scaledvol <- dat$Volume/avgvol * 100

  ## now extend the data frame with a few new columns
  D <- cbind(dat, bbmiddle, bbsd, bbupper, bblower, avgvol, scaledvol)

  D                                     # return the augmented data frame
}

## plot Bollinger Bars for the given Open/Low/High/Close data frame
plotBollingerBars <- function(X) {
  x <- 1:NROW(X)                        # simple index
  plot.new()                            # empty plot
  oldpar <- par(mar=c(0,4,2,4),         # no bottom spacing
                ylog=TRUE,              # plot on log(price) axis
                lend="square")          # square line ends

  ## set up coordinates
  plot.window(range(x), range(X[,c("Open","Low","High","Close",
                                   "bblower","bbmiddle","bbupper")],
                              na.rm=TRUE),
              xaxs="i") 
  grid()                                # dashed grid

  lines(x, X$bbupper, col='red')        # Bbands: upper in red
  lines(x, X$bbmiddle, col='blue')      # Bbands: middle in blue
  lines(x, X$bblower, col='green')      # Bbands: lower in green
    
  ## part one: blue bars for the days intraday extension from the higher
  ## 	    of Open and Close to the High
  segments(x, apply(X[,c("Open","Close")], 1, max), x, X$High,
           col="blue", lwd=2)

  ## part two: for winning days where close is higher than open, plot
  ##	    green bars showing advance from the open to the close
  ind <- which(X$Close > X$Open)
  segments(x[ind], X[ind,"Open"], x[ind], X[ind,"Close"],
           col="green", lwd=2)

  ## part three: for losing days where close is lower than open, plot
  ##	    red bars showing retreat from the open to the close
  ind <- which(X$Close < X$Open)
  segments(x[ind], X[ind,"Open"], x[ind], X[ind,"Close"],
           col="red", lwd=2)

  ## part four: blue bars for the days intraday retreat from the lower
  ## 	    of Open and Close to the Low
  segments(x, X$Low, x, apply(X[,c("Open","Close")], 1, min),
           col="blue", lwd=2)

  axis(2)
  #axis(4, pos=par("usr")[1], line=0.5)  # this would plot them 'inside'
  title(ylab="log(Price)")              # y-axis label
  box()                                 # outer box

  par(oldpar)
}

plotBollingerIndicators <- function(X) {

  bbwidth <- 100*(X$bbupper-X$bblower)/X$bbmiddle
  bbpct <- (X$Close-X$bblower)/(X$bbupper-X$bblower)

  x <- 1:NROW(X)

  oldpar <- par(mar=c(0,4,0,4))         # no top spacing

  plot(x, bbwidth, col='blue', ylab="", type='l', axes=FALSE, xaxs="i",
       ylim=c(min(0, min(bbwidth)) ,max(bbwidth)))
  abline(h=100, lty='dotted', col='blue')
  grid()
  title(ylab="Bandwidth", col.lab='blue') # title the y-axis in blue too
  axis(2, col.axis='blue')              # y-axis

  par(new=TRUE)                         # add to the plot
  plot(x, bbpct, col='red', type='l', ylab="", axes=FALSE, xaxs="i")
  abline(h=c(0,1), lty='dotted', col='red')
  axis(4, col.axis='red')
  ## need mtext() to annotate 2nd y-axis as title() doesn't do it
  mtext("%b", side=4, col='red', line=3, las=0, cex=0.73) 
  box()                                 # outer box

  par(oldpar)
}

## plot volume bars
plotVolumeBars <- function(X) {
  x <- 1:NROW(X)
  ## to some trickery to scale the volume: use log to the basis of thousand
  ## to find the closest basis of thousands, but ensure we pick at least 1
  ## but also ensure that we do not pick higher than 3 (aka billions)
  volDivisor <- max(1, min(3, round(log(mean(X$Volume))/log(1e3))))
  ## for 1, 2, or 3, pick the power of thousand (for display purposes)
  volDivText <- switch(volDivisor,
                       '(thousands)',
                       '(millions)',
                       '(billions)')
  Vol <- X$Volume/1e3^volDivisor        # scale volume down

  oldpar <- par(mar=c(0,4,0,4),         # no top spacing
                lend="square")          # square line ends

  plot.new()                            # empty plot
  plot.window(range(x), range(X$scaledvol), xaxs="i")     # set up coordinates
  grid()                                # dashed grid
  segments(x, 0, x, X$scaledvol, col="blue", lwd=1)
  abline(h=100, lty='dotted', col='red')
  title(ylab="Norm. Volume", col.lab='blue')
  axis(2, col.axis='blue')              # y-axis

  par(new=TRUE)                         # add to the plot
  plot(x, Vol, col='darkgray', type='l', ylab="", axes=FALSE, xaxs="i")
  axis(4, col.axis='darkgray')
  ## need mtext() to annotate 2nd y-axis as title() doesn't do it
  mtext(paste("Volume", volDivText),
        side=4, col='darkgray', line=3, las=0, cex=0.73) 

  box()                                 # outer box
  lab.ind <- seq(1, NROW(X), length=6)
  axis(1, at=lab.ind, lab=rownames(X)[lab.ind])

  par(oldpar)
}

BollingerBands <- function(instrument,x) {
  X <- x
  #getData(instrument)
  useObs <- 100                         # use this many observations
  X <- computeBollingerBands(X, 20, 2)
  X <- X[(NROW(X)-useObs):NROW(X),]     # limit to recent useObs obs.

  ## layout is a fairly user-unfriendly function for chart layout that is
  ## being replaced by grid and gridBase -- but I'm still more familiar
  ## with this one. The following says have two plots plotted in the 
  ## order 1 and 2, one on top of the other, with 75% and 25% of the spave
  layout(matrix(c(1,2,3),3,1,byrow=TRUE),
         height=c(0.75,0.125,0.125), width=1)

  ## set 'global' plot parameters: horizontal y-axis labels, tighter spacing
  ## and no outer spacing
  oldpar <- par(las=1, mar=c(2,4,2,4), oma=c(2.5,0.5,1.5,0.5))
  plotBollingerBars(X)
  mtext(paste(instrument, ": Bollinger Bars, Bands, Indicators and ",
              "normalized and absolute Volume", sep=""),
        3, outer=FALSE, line=1, cex=1.0, font=2)
  plotBollingerIndicators(X)
  plotVolumeBars(X)
  par(oldpar)                           # restore graphics parameters
  invisible(X)
  
  X
}







chartSeries.demo <- function(x) {
data(sample_matrix, package="xts")
data <- x#as.xts(sample_matrix)
cat("A simple xts object:\n")
print(str(data))
candleChart(data,multi.col=TRUE,theme="white") 
cat("chartSeries(data)\n")
# chartSeries(data)
readline("Press <Enter> to continue")
cat("Now we can add builtin indicators:\n\n")
cat("Moving Average Convergence Divergence Indicator (from TTR)\n> addMACD()\n")
plot(addMACD())

plot(addMomentum())
readline("Press <Enter> to continue")
cat("Add Bollinger Bands\n> addBBands()\n")
plot(addBBands())
readline("Press <Enter> to continue")
cat("Drop Bollinger Bands\n> dropTA('BBands')\n")
dropTA('BBands')
readline("Press <Enter> to continue")
cat("Zoom chart from full data to last 3 months\n> zoomChart(\"last 3 months\")\n")
zoomChart('last 3 months')
readline("Press <Enter> to continue")
cat("Zoom back to full data\n> zoomChart()\n\n")
zoomChart()
rm(data)
}





instrument <- "AAPL"
X <- getData(instrument);
BollingerBands(instrument,X)
chartSeries.demo(X)
a <- sample_matrix;
print(a)

dev.off()

