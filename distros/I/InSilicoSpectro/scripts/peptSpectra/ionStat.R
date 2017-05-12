# Minimal R script for plotting ion intensity distributions

# Copyright (C) 2005 Jacques Colinge

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Sciences at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  http://www.fhs-hagenberg.ac.at

ionDensityHist<-function(d, xlab, col=rainbow(dim(d)[2]), lty=1, lwd=2, br=30)
{
  n<-dim(d)[2]
  m<-0
  for (i in 1:n){
    h<-hist(d[[i]], breaks=br, plot=FALSE)
    s<-max(h$density)
    if (s > m) m<-s
  }
  h<-hist(d[[1]], breaks=br, plot=FALSE)
  plot(h$density, x=h$mids, type="l", ylim=c(0,m), main="ion probability densities", ylab="density", xlab=xlab, col=col[1], lwd=lwd, lty=lty)
  for (i in 2:n){
    h<-hist(d[[i]], breaks=br, plot=FALSE)
    lines(h$density, x=h$mids, type="l", col=col[i], lwd=lwd, lty=lty)
  }
  legend(0, m, legend=names(d), lwd=lwd, lty=lty, col=col)
}

ionFreqHist<-function(d, xlab, col=rainbow(dim(d)[2]), relative=FALSE, lty=1, lwd=2, br=30)
{
  n<-dim(d)[2]
  m<-0
  for (i in 1:n){
    h<-hist(d[[i]], breaks=br, plot=FALSE)
    s<-ifelse(relative, max(h$counts/sum(h$counts)), max(h$counts))
    if (s > m) m<-s
  }
  h<-hist(d[[1]], breaks=br, plot=FALSE)
  plot(ifelse(rep(relative, length(h$counts)), h$counts/sum(h$counts), h$counts), x=h$mids, type="l", ylim=c(0,m), main="ion frequencies", ylab="frequency", xlab=xlab, col=col[1], lwd=lwd, lty=lty)
  for (i in 2:n){
    h<-hist(d[[i]], breaks=br, plot=FALSE)
    lines(ifelse(rep(relative, length(h$counts)), h$counts/sum(h$counts), h$counts), x=h$mids, type="l", col=col[i], lwd=lwd, lty=lty)
  }
  legend(0, m, legend=names(d), lwd=lwd, lty=lty, col=col)
}

