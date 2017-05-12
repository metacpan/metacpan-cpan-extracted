var edito = "24//06//2002";
edito +="";

// edito += "Une nouvelle page d'acceuil pour 1001cartes, notre site de cartes virtuelles... ";
//edito += " La fête d'HALLOWEEN est passée, mais les enfants restent dans l'ambiance encore toutes les vacances... ";
edito += " L'été est là, il fait chaud, et c'est bientôt les vacances ! N'oubliez pas d'envoyer une carte postale... ";

function verifieUrl()
  {
  if (parent.document.location!=this.document.location)  
    {parent.document.location=this.document.location;}
  }
// Fonction de scroll dans la barre des status
function scrollit_r2l(seed)
{
  verifieUrl();
        var m1  =edito;
        var msg=m1;
        var out = " ";
        var c   = 1;
        if (seed > 100) 
          {
                seed--;
                var cmd="scrollit_r2l(" + seed + ")";
                timerTwo=window.setTimeout(cmd,50);
              }
        else if (seed <= 100 && seed > 0) 
                {
                for (c=0 ; c < seed ; c++) {out+=" ";}
                out+=msg;
                seed--;
                var cmd="scrollit_r2l(" + seed + ")";
                    window.status=out;
                timerTwo=window.setTimeout(cmd,50);
             }
       else if (seed <= 0) 
    {
                if (-seed < msg.length) 
      {
                        out+=msg.substring(-seed,msg.length);
                        seed--;
                        var cmd="scrollit_r2l(" + seed + ")";
                        window.status=out;
                        timerTwo=window.setTimeout(cmd,50);
                  }
                else 
          {
         window.status=" ";
                        timerTwo=window.setTimeout("scrollit_r2l(100)",50);
                  }
          }
  }

function checkMoteur(theForm)
{

  if (theForm.MOT_CLEF.value == "")
  {
    alert("Vous devez donnez des mots-clefs pour effectuer votre recherche .");
    theForm.MOT_CLEF.focus();
    return (false);
  }

  if (theForm.MOT_CLEF.value.length < 2)
  {
    alert("Tapez au moins 2 caractères pour que votre recherche soit pertinente .");
    theForm.MOT_CLEF.focus();
    return (false);
  }
  return (true);
}

function checkMail(theForm)
{

  if (theForm.mail.value == "<Votre adresse Mail>")
  {
    alert("Vous devez donnez votre adresse Mail.");
    theForm.mail.focus();
    return (false);
  }

  if (theForm.mail.value.length < 5)
  {
    alert("Tapez au moins 5 caractres dans le champ \"mail\".");
    theForm.mail.focus();
    return (false);
  }

  if (theForm.mail.value.length > 30)
  {
    alert("Tapez au plus 30 caractres dans le champ \"mail\".");
    theForm.mail.focus();
    return (false);
  }
  return (true);
}
function banner(msg,ctrlwidth)
  {
  document.write ('<APPLET CODE=scroll WIDTH=400 HEIGHT=16>');
  document.write ('<PARAM NAME=TEXT VALUE="$' + edito + '$">');
  document.write ('<PARAM NAME=SPEED VALUE=fast></APPLET>');  
  }
