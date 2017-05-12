if (!Jamila) var Jamila = function(sURL, fSt, fEnd, fExp)
{
  var _defURL = '';
  this._dispWin = true;
  this._sURL = (sURL == undefined)? _defURL : sURL;
  this._fSt = fSt;
  this._fEnd = fEnd;
  this._fExp = fExp;

  var _responseTxt;
  //---------------------------------------------------------------------
  // handleError : Error Handling
  //---------------------------------------------------------------------
  this.handleError = function(sMsg)
  {
    if(this._fExp) {
      this._fExp(sMsg)
    }
    else {
      throw(sMsg);
    }
  };
  //---------------------------------------------------------------------
  // call : send query with POST/GET
  //---------------------------------------------------------------------
  //this.call = function(aPrm, fFail, fExp, bGet) 
  this.call = function(sFunc) 
  {
    var aPrm;
    var that = this;
    var fFail = function(oXml) { that.handleError('FAIL in Ajax.Request'); }
    var fExp = function(oXml, oExp) 
              {  if(that._fEnd) that._fEnd();
                 that.handleError(' Exception in Ajax.Request with:' + 
                       (oExp.number  & 0xffff) + "\n" + oExp.description);
              };
    var bGet = false;

    if(typeof(sFunc) == 'object')
    {
      if(arguments.length >= 1) aPrm  = arguments[0];
      if(arguments.length >= 2) fFail = arguments[1];
      if(arguments.length >= 3) fExp  = arguments[2];
      if(arguments.length >= 4) bGet  = arguments[3];
    }
    else
    {
      aPrm = Array.prototype.slice.call(arguments);
    }
    // Call Local
    if(typeof(this._sURL) == 'object')
    {
      var sMethod = aPrm.shift();
      return this._sURL[sMethod](aPrm);
    }

    if(this._fSt) this._fSt();

    this._responseTxt = '';
    var sPath = this._sURL;
    var hReq = 
        {
          asynchronous:false,
          onFailure:   fFail,
          onException: fExp
        };
    var sPrm = (!aPrm)? '' : 
          ('_prm=' + encodeURIComponent(Object.toJSON(aPrm)));
    if(bGet)
    {
      hReq['method'] = 'get';
      if(sPrm != '') sPath += '?' + sPrm;
    }
    else
    {
      hReq['method'] = 'post';
      hReq['parameters'] = sPrm;
    }
    var oReq = new Ajax.Request(sPath, hReq);
    this._responseTxt = oReq.transport.responseText;

    if(this._fEnd) this._fEnd();

    var aRes = this._responseTxt.evalJSON();
    if(aRes['error']) 
    { 
      if(this._fExp) {
        this._fExp(aRes['error'])
      }
      else
      {
         this.handleError(aRes['error']);
      }
    }
    else
    {
      return aRes['result'];
    }
  };
  //---------------------------------------------------------------------
  // getResponseTxt : get Document object
  //---------------------------------------------------------------------
  this.getResponseTxt = function() 
  {
    return this._responseTxt;
  };
};
