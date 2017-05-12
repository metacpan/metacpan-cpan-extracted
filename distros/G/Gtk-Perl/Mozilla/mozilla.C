//#include <mozilla/gtkmozembed_internal.h>
#include <mozilla/nsCOMPtr.h>
#include <mozilla/nsIPref.h>
#include <glib.h>

#define PREF_ID NS_PREF_CONTRACTID

extern "C" gboolean
mozilla_preference_set(const char *preference_name, const char *new_value)
{
  g_return_val_if_fail (preference_name != NULL, FALSE);
  g_return_val_if_fail (new_value != NULL, FALSE);
  nsCOMPtr<nsIPref> pref = do_CreateInstance(PREF_ID);

  if (pref)
    {
      nsresult rv = pref->SetCharPref (preference_name, new_value);            
      return NS_SUCCEEDED (rv) ? TRUE : FALSE;
    }
  
  return FALSE;
}

extern "C" gboolean
mozilla_preference_set_boolean (const char        *preference_name,
                                gboolean        new_boolean_value)
{
  g_return_val_if_fail (preference_name != NULL, FALSE);
  
  nsCOMPtr<nsIPref> pref = do_CreateInstance(PREF_ID);
  
  if (pref)
    {
      nsresult rv = pref->SetBoolPref (preference_name,
                                       new_boolean_value ? PR_TRUE : PR_FALSE);
      
      return NS_SUCCEEDED (rv) ? TRUE : FALSE;
    }
  
  return FALSE;
}

extern "C" gboolean
mozilla_preference_set_int (const char        *preference_name,
                                int        new_int_value)
{
  g_return_val_if_fail (preference_name != NULL, FALSE);
  
  nsCOMPtr<nsIPref> pref = do_CreateInstance(PREF_ID);
  
  if (pref)
    {
      nsresult rv = pref->SetIntPref (preference_name,
                                       new_int_value);
      
      return NS_SUCCEEDED (rv) ? TRUE : FALSE;
    }
  
  return FALSE;
}

